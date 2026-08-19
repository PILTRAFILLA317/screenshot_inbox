import 'dart:async';
import 'dart:io';

import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';
import 'package:screenshot_inbox/processing/intelligence/interpretation_validator.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_version.dart';

final class IntelligenceEnrichmentResult {
  const IntelligenceEnrichmentResult({
    required this.objects,
    required this.diagnostics,
  });

  final List<ExtractedObject> objects;
  final JsonMap diagnostics;
}

final class IntelligenceEnricher {
  IntelligenceEnricher({
    required this.provider,
    required this.validator,
    required this.policy,
    required this.clock,
    required this.ids,
    this.timeout = const Duration(seconds: 20),
    String Function()? locale,
    String Function()? timezone,
  }) : _locale = locale ?? (() => Platform.localeName),
       _timezone = timezone ?? (() => DateTime.now().timeZoneName);

  final IntelligenceProvider provider;
  final InterpretationValidator validator;
  final IntelligenceUsagePolicy policy;
  final Clock clock;
  final IdGenerator ids;
  final Duration timeout;
  final String Function() _locale;
  final String Function() _timezone;
  Future<void> _serialTail = Future.value();

  Future<IntelligenceEnrichmentResult> enrich({
    required ProcessingContext context,
    required ParseResult deterministic,
    List<ExtractedObject> existingObjects = const [],
  }) async {
    final base = deterministic.objects;
    if (base.isEmpty || !_shouldInterpret(context, base)) {
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(base, existingObjects),
        diagnostics: {
          'policy': policy.name,
          'skipped': true,
          'reason': base.isEmpty ? 'no deterministic candidate' : 'policy',
        },
      );
    }

    final availability = await provider.availability();
    if (!availability.isAvailable) {
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(base, existingObjects),
        diagnostics: {
          'policy': policy.name,
          'availability': availability.toJson(),
          'skipped': true,
          'reason': 'provider unavailable; deterministic fallback used',
        },
      );
    }

    final request = _request(context, base);
    try {
      final result = await _serialized(
        () => provider.interpret(request).timeout(timeout),
      );
      final validations = <ValidatedInterpretation>[];
      for (var index = 0; index < result.interpretations.length; index++) {
        final candidate = base.length > index ? base[index] : base.first;
        validations.add(
          validator.validate(
            interpretation: result.interpretations[index],
            request: request,
            deterministicCandidate: _candidateJson(candidate),
          ),
        );
      }
      final resolved = result.interpretations.isEmpty
          ? _noActionObjects(base, result)
          : _resolve(base, validations, result);
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(resolved, existingObjects),
        diagnostics: {
          'policy': policy.name,
          'availability': availability.toJson(),
          'provider': result.provider,
          'providerVersion': ?result.providerVersion,
          'durationMs': result.duration.inMilliseconds,
          'rawStructuredResult': result.toJson(),
          'validation': validations
              .map((item) => item.toJson())
              .toList(growable: false),
        },
      );
    } catch (error) {
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(base, existingObjects),
        diagnostics: {
          'policy': policy.name,
          'availability': availability.toJson(),
          'skipped': true,
          'reason': error is TimeoutException
              ? 'local intelligence timed out'
              : 'local intelligence failed: ${error.runtimeType}',
        },
      );
    }
  }

  bool _shouldInterpret(
    ProcessingContext context,
    List<ExtractedObject> objects,
  ) {
    if (policy == IntelligenceUsagePolicy.disabled) return false;
    final type = objects.first.type.value;
    if (!_actionableTypes.contains(type)) return false;
    if (policy == IntelligenceUsagePolicy.lowConfidenceOnly) {
      return (context.classification?.confidence ?? 0) < 0.75;
    }
    return true;
  }

  IntelligenceRequest _request(
    ProcessingContext context,
    List<ExtractedObject> objects,
  ) => IntelligenceRequest(
    typeHint: context.classification?.type.value,
    screenshotCapturedAt: context.screenshot.createdAt,
    currentTime: clock.now(),
    locale: _locale(),
    timezone: _timezone(),
    blocks: [
      for (
        var blockIndex = 0;
        blockIndex < context.recognizedText.blocks.length;
        blockIndex++
      )
        OcrBlockInput(
          id: context.recognizedText.blocks[blockIndex].id,
          text: context.recognizedText.blocks[blockIndex].text,
          order: blockIndex,
          bounds: context.recognizedText.blocks[blockIndex].boundingBox
              ?.toJson(),
          lines: [
            for (final line in context.recognizedText.blocks[blockIndex].lines)
              {
                'id': line.id,
                'text': line.text,
                'bounds': ?line.boundingBox?.toJson(),
              },
          ],
        ),
    ],
    entities: context.entities.map(_entityJson).toList(growable: false),
    deterministicCandidates: objects
        .map(_candidateJson)
        .toList(growable: false),
    interpretationVersion: ProcessingVersion.intelligence,
  );

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _serialTail = _serialTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  List<ExtractedObject> _resolve(
    List<ExtractedObject> deterministic,
    List<ValidatedInterpretation> validations,
    IntelligenceResult result,
  ) {
    if (validations.isEmpty) return deterministic;
    final resolved = <ExtractedObject>[];
    for (var index = 0; index < validations.length; index++) {
      final validation = validations[index];
      final base = deterministic.length > index
          ? deterministic[index]
          : _emptyObject(deterministic.first, validation.type);
      resolved.add(_merge(base, validation, result));
    }
    if (deterministic.length > validations.length) {
      resolved.addAll(deterministic.skip(validations.length));
    }
    return resolved;
  }

  List<ExtractedObject> _noActionObjects(
    List<ExtractedObject> base,
    IntelligenceResult result,
  ) => [
    for (final object in base)
      object.copyWith(
        type: ExtractedObjectType.reference,
        subtype: 'reference.local-ai-no-action',
        confidence: 0.75,
        structuredData: {
          ...object.structuredData,
          '_suppressActions': true,
          '_intelligence': {
            'provider': result.provider,
            'providerVersion': ?result.providerVersion,
            'interpretationVersion': ProcessingVersion.intelligence,
            'timestamp': clock.now().toIso8601String(),
            'decision': 'noActionableObject',
          },
        },
        updatedAt: clock.now(),
      ),
  ];

  ExtractedObject _merge(
    ExtractedObject base,
    ValidatedInterpretation validation,
    IntelligenceResult result,
  ) {
    final data = <String, Object?>{...base.structuredData};
    final metadata = _deterministicFieldMetadata(base);
    var title = base.title;
    for (final entry in validation.fields.entries) {
      if (entry.key == 'title') {
        title = entry.value.value.toString();
      } else {
        data[entry.key] = entry.value.value;
      }
      metadata[entry.key] = entry.value.toJson();
    }
    _deriveTemporalFields(validation.type, data);
    _derivePresentationFields(validation.type, title, data);
    data['_fieldMetadata'] = metadata;
    data['_intelligence'] = {
      'provider': result.provider,
      'providerVersion': ?result.providerVersion,
      'interpretationVersion': ProcessingVersion.intelligence,
      'ocrVersion': ProcessingVersion.ocr,
      'parserVersion': ProcessingVersion.parser,
      'timestamp': clock.now().toIso8601String(),
    };
    final confidences = validation.fields.values
        .map((field) => field.confidence)
        .toList(growable: false);
    final confidence = confidences.isEmpty
        ? base.confidence
        : confidences.reduce((a, b) => a + b) / confidences.length;
    return base.copyWith(
      type: ExtractedObjectType(validation.type),
      subtype: validation.subtype ?? '${validation.type}.local-ai',
      title: title,
      subtitle: _subtitle(validation.type, data) ?? base.subtitle,
      structuredData: data,
      confidence: confidence,
      updatedAt: clock.now(),
    );
  }

  List<ExtractedObject> _preserveUserFields(
    List<ExtractedObject> generated,
    List<ExtractedObject> existing,
  ) {
    if (generated.isEmpty || existing.isEmpty) return generated;
    final old = existing.first;
    final rawFields = old.structuredData['_userConfirmedFields'];
    final fields = rawFields is List
        ? rawFields.whereType<String>().toSet()
        : <String>{};
    if (fields.isEmpty && !old.saved && !old.handled) return generated;
    final next = generated.first;
    final data = <String, Object?>{...next.structuredData};
    final rawMetadata = data['_fieldMetadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry(key.toString(), value))
        : <String, Object?>{};
    for (final field in fields) {
      if (field == 'title' || field == 'type') continue;
      if (old.structuredData.containsKey(field)) {
        data[field] = old.structuredData[field];
        metadata[field] = {
          'source': FieldProvenance.userConfirmed.name,
          'confidence': 1.0,
          'confidenceBasis': ConfidenceBasis.heuristic.name,
          'evidence': const <String>[],
        };
      }
    }
    if (fields.contains('importantDate')) {
      for (final field in const [
        'importantDate',
        'startsAt',
        'expiresAt',
        'remindAt',
        'deliveryDate',
      ]) {
        if (old.structuredData.containsKey(field)) {
          data[field] = old.structuredData[field];
        }
      }
    }
    if (fields.contains('type')) data.remove('_suppressActions');
    data['_fieldMetadata'] = metadata;
    data['_userConfirmedFields'] = fields.toList(growable: false);
    return [
      next.copyWith(
        type: fields.contains('type') ? old.type : next.type,
        title: fields.contains('title') ? old.title : next.title,
        structuredData: data,
        saved: old.saved,
        handled: old.handled,
      ),
      ...generated.skip(1),
    ];
  }

  ExtractedObject _emptyObject(ExtractedObject base, String type) =>
      ExtractedObject(
        id: ids.next(),
        screenshotId: base.screenshotId,
        type: ExtractedObjectType(type),
        subtype: '$type.local-ai',
        title: type,
        structuredData: const {},
        confidence: 0.5,
        saved: false,
        handled: false,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  static JsonMap _entityJson(ExtractedEntity entity) => {
    'id': entity.id,
    'type': entity.type.value,
    'rawValue': entity.rawValue,
    'normalizedValue': entity.normalizedValue,
    'confidence': entity.confidence,
    'metadata': entity.metadata,
  };

  static JsonMap _candidateJson(ExtractedObject object) => {
    'id': object.id,
    'type': object.type.value,
    'subtype': object.subtype,
    'title': object.title,
    'confidence': object.confidence,
    'fields': {
      for (final entry in object.structuredData.entries)
        if (!entry.key.startsWith('_') &&
            entry.key != 'classificationReasons' &&
            entry.key != 'entityIds')
          entry.key: entry.value,
    },
  };

  static Map<String, Object?> _deterministicFieldMetadata(
    ExtractedObject object,
  ) => {
    'title': {
      'source': FieldProvenance.machineDeterministic.name,
      'confidence': object.confidence,
      'confidenceBasis': ConfidenceBasis.heuristic.name,
      'evidence': const <String>[],
    },
    for (final entry in object.structuredData.entries)
      if (!entry.key.startsWith('_') &&
          entry.key != 'classificationReasons' &&
          entry.key != 'entityIds')
        entry.key: {
          'source': FieldProvenance.machineDeterministic.name,
          'confidence': object.confidence,
          'confidenceBasis': ConfidenceBasis.heuristic.name,
          'evidence': const <String>[],
        },
  };

  static void _deriveTemporalFields(String type, Map<String, Object?> data) {
    final date = data['date'];
    final time = data['time'];
    if (date is String) {
      final local = time is String ? '${date}T$time:00' : '${date}T00:00:00';
      if (DateTime.tryParse(local) != null) {
        if (type == 'event') data['startsAt'] = local;
        if (type == 'conversationTask') data['remindAt'] = local;
      }
    }
    final expiry = data['expiryDate'];
    if (expiry is String && DateTime.tryParse(expiry) != null) {
      data['expiresAt'] = '${expiry}T23:59:59';
    }
  }

  static void _derivePresentationFields(
    String type,
    String title,
    Map<String, Object?> data,
  ) {
    if (type == 'place') {
      data['mapsQuery'] = [
        data['name'] ?? title,
        data['address'],
        data['city'],
      ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    }
  }

  static String? _subtitle(String type, Map<String, Object?> data) =>
      switch (type) {
        'event' => (data['venue'] ?? data['city']) as String?,
        'coupon' =>
          data['couponCode'] is String ? 'Code ${data['couponCode']}' : null,
        'product' => data['price'] as String?,
        'place' => (data['address'] ?? data['city']) as String?,
        'conversationTask' => data['person'] as String?,
        'order' =>
          data['trackingNumber'] is String
              ? 'Tracking ${data['trackingNumber']}'
              : null,
        _ => null,
      };

  static const _actionableTypes = {
    'event',
    'coupon',
    'place',
    'product',
    'conversationTask',
    'order',
  };
}
