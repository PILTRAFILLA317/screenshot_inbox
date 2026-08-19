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
    final policyDecision = _policyDecision(context, base);
    if (!policyDecision.invoke) {
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(base, existingObjects),
        diagnostics: {
          'policy': policy.name,
          'provider': null,
          'availability': null,
          'invoked': false,
          'skipped': true,
          'imageInput': false,
          'ocrInput': false,
          'durationMs': 0,
          'result': 'policySkipped',
          'reason': 'policySkipped',
          'policyDecision': policyDecision.reason,
        },
      );
    }

    final availability = await provider.availability();
    if (!availability.isAvailable) {
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(base, existingObjects),
        diagnostics: {
          'policy': policy.name,
          'provider': availability.provider,
          'providerVersion': ?availability.providerVersion,
          'availability': availability.state.name,
          'availabilityDetail': availability.toJson(),
          'invoked': false,
          'skipped': true,
          'imageInput': false,
          'ocrInput': false,
          'durationMs': 0,
          'result': 'providerUnavailable',
          'reason': 'providerUnavailable',
        },
      );
    }

    final request = _request(context, base);
    final invocationWatch = Stopwatch()..start();
    try {
      final result = await _serialized(
        () => provider.interpret(request).timeout(timeout),
      );
      invocationWatch.stop();
      final validationWatch = Stopwatch()..start();
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
      validationWatch.stop();
      final invalidResult =
          result.interpretations.isNotEmpty &&
          validations.every(
            (validation) =>
                _actionableTypes.contains(validation.type) &&
                validation.fields.isEmpty,
          );
      if (invalidResult) {
        return IntelligenceEnrichmentResult(
          objects: _preserveUserFields(base, existingObjects),
          diagnostics: _diagnostics(
            availability: availability,
            result: result,
            invoked: true,
            resultStatus: 'invalidResult',
            reason: 'invalidResult',
            durationMs: invocationWatch.elapsedMilliseconds,
            validations: validations,
            validationDurationMs: validationWatch.elapsedMilliseconds,
          ),
        );
      }
      final resolved = result.interpretations.isEmpty
          ? _noActionObjects(base, result)
          : _resolve(base, validations, result);
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(resolved, existingObjects),
        diagnostics: _diagnostics(
          availability: availability,
          result: result,
          invoked: true,
          resultStatus: 'success',
          durationMs: invocationWatch.elapsedMilliseconds,
          validations: validations,
          validationDurationMs: validationWatch.elapsedMilliseconds,
        ),
      );
    } catch (error) {
      invocationWatch.stop();
      final status = error is TimeoutException
          ? 'timeout'
          : error is FormatException
          ? 'invalidResult'
          : 'providerError';
      return IntelligenceEnrichmentResult(
        objects: _preserveUserFields(base, existingObjects),
        diagnostics: {
          'policy': policy.name,
          'provider': availability.provider,
          'providerVersion': ?availability.providerVersion,
          'availability': availability.state.name,
          'availabilityDetail': availability.toJson(),
          'invoked': true,
          'skipped': true,
          'imageInput': false,
          'ocrInput': false,
          'requestImageProvided': request.imageBytes.isNotEmpty,
          'requestOcrProvided': request.blocks.isNotEmpty,
          'durationMs': invocationWatch.elapsedMilliseconds,
          'result': status,
          'reason': status,
          'errorType': error.runtimeType.toString(),
        },
      );
    }
  }

  _PolicyDecision _policyDecision(
    ProcessingContext context,
    List<ExtractedObject> objects,
  ) {
    if (policy == IntelligenceUsagePolicy.disabled) {
      return const _PolicyDecision(false, 'Intelligence is disabled.');
    }
    if (objects.isEmpty) {
      return const _PolicyDecision(false, 'No deterministic candidate.');
    }
    final type = objects.first.type.value;
    if (policy == IntelligenceUsagePolicy.alwaysForSupportedTypes) {
      return _providerSupportedTypes.contains(type)
          ? const _PolicyDecision(
              true,
              'Debug policy invokes all provider-supported types.',
            )
          : _PolicyDecision(
              false,
              'Type $type is unsupported by the provider.',
            );
    }
    if (!_actionableTypes.contains(type)) {
      return _PolicyDecision(false, 'Type $type is not actionable.');
    }
    if (policy == IntelligenceUsagePolicy.lowConfidenceOnly &&
        (context.classification?.confidence ?? 0) >= _lowConfidenceThreshold) {
      return const _PolicyDecision(
        false,
        'Deterministic classification met the confidence threshold.',
      );
    }
    return const _PolicyDecision(true, 'Policy selected local intelligence.');
  }

  IntelligenceRequest _request(
    ProcessingContext context,
    List<ExtractedObject> objects,
  ) => IntelligenceRequest(
    typeHint: context.classification?.type.value,
    schemaHint: _schemaFor(context.classification?.type.value),
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
                'confidence': ?line.confidence,
              },
          ],
          confidence: _blockConfidence(
            context.recognizedText.blocks[blockIndex].lines,
          ),
          weight: context.ocrAnalysis
              .signalFor(context.recognizedText.blocks[blockIndex].id)
              .weight,
          signals: context.ocrAnalysis
              .signalFor(context.recognizedText.blocks[blockIndex].id)
              .reasons,
          duplicateOf: context.ocrAnalysis
              .signalFor(context.recognizedText.blocks[blockIndex].id)
              .duplicateOf,
        ),
    ],
    entities: context.entities.map(_entityJson).toList(growable: false),
    deterministicCandidates: objects
        .map(_candidateJson)
        .toList(growable: false),
    imageBytes: context.imageBytes,
    imageWidth: context.screenshot.width,
    imageHeight: context.screenshot.height,
    interpretationVersion: ProcessingVersion.intelligence,
  );

  JsonMap _diagnostics({
    required IntelligenceAvailability availability,
    required IntelligenceResult result,
    required bool invoked,
    required String resultStatus,
    required int durationMs,
    required List<ValidatedInterpretation> validations,
    required int validationDurationMs,
    String? reason,
  }) => {
    'policy': policy.name,
    'provider': result.provider,
    'providerVersion': ?result.providerVersion,
    'availability': availability.state.name,
    'availabilityDetail': availability.toJson(),
    'invoked': invoked,
    'skipped': false,
    'imageInput': result.imageInput,
    'ocrInput': result.ocrInput,
    'inputImageWidth': ?result.inputImageWidth,
    'inputImageHeight': ?result.inputImageHeight,
    'durationMs': result.duration.inMilliseconds > 0
        ? result.duration.inMilliseconds
        : durationMs,
    'validationDurationMs': validationDurationMs,
    'result': resultStatus,
    'reason': ?reason,
    'rawStructuredResult': result.toJson(),
    'validation': validations
        .map((item) => item.toJson())
        .toList(growable: false),
  };

  static String _schemaFor(String? type) => switch (type) {
    'event' => 'event',
    'place' => 'place',
    'product' || 'order' => 'commerce',
    'coupon' => 'coupon',
    'conversationTask' => 'conversationTask',
    _ => 'general',
  };

  static double? _blockConfidence(List<dynamic> lines) {
    final values = lines
        .map((line) => line.confidence)
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce((left, right) => left + right) / values.length;
  }

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
        title: 'Reference',
        clearSubtitle: true,
        confidence: 0.75,
        structuredData: {
          for (final entry in object.structuredData.entries)
            if (entry.key == '_parserId' ||
                entry.key == 'classificationReasons' ||
                entry.key == 'entityIds')
              entry.key: entry.value,
          '_fieldMetadata': const <String, Object?>{},
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
    final data = <String, Object?>{
      for (final entry in base.structuredData.entries)
        if (entry.key == '_parserId' ||
            entry.key == 'classificationReasons' ||
            entry.key == 'entityIds')
          entry.key: entry.value,
    };
    final metadata = <String, Object?>{};
    String? validatedTitle;
    for (final entry in validation.fields.entries) {
      if (entry.key == 'title') {
        validatedTitle = entry.value.value.toString();
      } else {
        data[entry.key] = entry.value.value;
      }
      metadata[entry.key] = entry.value.toJson();
    }
    final title =
        validatedTitle ??
        _titleFromFields(validation.type, data) ??
        _fallbackTitle(validation.type);
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
    final subtitle = _subtitle(validation.type, data);
    return base.copyWith(
      type: ExtractedObjectType(validation.type),
      subtype: validation.subtype ?? '${validation.type}.local-ai',
      title: title,
      subtitle: subtitle,
      clearSubtitle: subtitle == null,
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
      final query = [
        data['address'],
        data['name'] ?? title,
        data['locality'],
        data['region'],
        data['country'],
      ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
      if (query.isNotEmpty) data['mapsQuery'] = query;
    }
  }

  static String? _titleFromFields(String type, Map<String, Object?> data) =>
      switch (type) {
        'place' => data['name'] as String?,
        'product' => data['productName'] as String?,
        'coupon' => data['merchant'] as String?,
        'conversationTask' => data['task'] as String?,
        'order' => data['merchant'] as String?,
        _ => null,
      };

  static String _fallbackTitle(String type) => switch (type) {
    'place' => 'Place',
    'product' => 'Possible product',
    'event' => 'Event',
    'order' => 'Possible order',
    'coupon' => 'Coupon',
    'conversationTask' => 'Conversation task',
    'reference' => 'Reference',
    _ => 'Screenshot',
  };

  static String? _subtitle(String type, Map<String, Object?> data) =>
      switch (type) {
        'event' => (data['venue'] ?? data['city']) as String?,
        'coupon' =>
          data['couponCode'] is String ? 'Code ${data['couponCode']}' : null,
        'product' => data['price'] as String?,
        'place' =>
          (data['address'] ?? data['locality'] ?? data['city']) as String?,
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

  static const _providerSupportedTypes = {
    ..._actionableTypes,
    'conversation',
    'reference',
    'other',
    'generic',
  };
  static const _lowConfidenceThreshold = 0.75;
}

final class _PolicyDecision {
  const _PolicyDecision(this.invoke, this.reason);

  final bool invoke;
  final String reason;
}
