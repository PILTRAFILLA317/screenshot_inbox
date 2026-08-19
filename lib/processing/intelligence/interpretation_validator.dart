import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';

final class ValidatedField {
  const ValidatedField({
    required this.name,
    required this.value,
    required this.confidence,
    required this.confidenceBasis,
    required this.source,
    required this.evidence,
    this.corroborated = false,
  });

  final String name;
  final Object value;
  final double confidence;
  final ConfidenceBasis confidenceBasis;
  final FieldProvenance source;
  final List<String> evidence;
  final bool corroborated;

  JsonMap toJson() => {
    'value': value,
    'confidence': confidence,
    'confidenceBasis': confidenceBasis.name,
    'source': source.name,
    'evidence': evidence,
    'corroborated': corroborated,
  };
}

final class ValidatedInterpretation {
  const ValidatedInterpretation({
    required this.type,
    required this.fields,
    required this.warnings,
    required this.rejectedFields,
    this.subtype,
  });

  final String type;
  final String? subtype;
  final Map<String, ValidatedField> fields;
  final List<String> warnings;
  final List<String> rejectedFields;

  JsonMap toJson() => {
    'type': type,
    'subtype': ?subtype,
    'fields': fields.map((key, value) => MapEntry(key, value.toJson())),
    'warnings': warnings,
    'rejectedFields': rejectedFields,
  };
}

final class InterpretationValidator {
  const InterpretationValidator();

  ValidatedInterpretation validate({
    required IntelligenceInterpretation interpretation,
    required IntelligenceRequest request,
    required JsonMap deterministicCandidate,
  }) {
    final warnings = <String>[];
    final rejected = <String>[];
    final accepted = <String, ValidatedField>{};
    final type = _supportedTypes.contains(interpretation.type)
        ? interpretation.type
        : request.typeHint;
    if (type == null || !_supportedTypes.contains(type)) {
      return ValidatedInterpretation(
        type: request.typeHint ?? 'other',
        fields: const {},
        warnings: const ['The model returned an unsupported object type.'],
        rejectedFields: interpretation.fields
            .map((field) => field.name)
            .toList(growable: false),
      );
    }

    final blocksById = {for (final block in request.blocks) block.id: block};
    final deterministicFields = _candidateFields(deterministicCandidate);
    final allowed = _allowedFields[type] ?? const <String>{};
    for (final field in interpretation.fields) {
      if (!allowed.contains(field.name)) {
        rejected.add(field.name);
        warnings.add('${field.name}: unsupported for $type.');
        continue;
      }
      final value = _normalize(field.name, field.value);
      if (value == null || !_valid(field.name, value, request)) {
        rejected.add(field.name);
        warnings.add('${field.name}: malformed or implausible value.');
        continue;
      }
      final evidence = field.evidence
          .where(
            (id) =>
                blocksById.containsKey(id) &&
                blocksById[id]!.weight >= _minimumEvidenceWeight &&
                _evidenceSupports(field.name, value, blocksById[id]!.text),
          )
          .toSet()
          .toList(growable: false);
      if (field.evidence.length != evidence.length) {
        warnings.add('${field.name}: invalid OCR evidence IDs were removed.');
      }
      final deterministic = deterministicFields[field.name];
      final corroborated =
          deterministic != null &&
          _comparable(deterministic) == _comparable(value);
      if (evidence.isEmpty) {
        rejected.add(field.name);
        warnings.add(
          '${field.name}: rejected because it has no reliable OCR evidence.',
        );
        continue;
      }
      if (!_contextSupports(field.name, evidence, request)) {
        rejected.add(field.name);
        warnings.add(
          '${field.name}: rejected because its surrounding context does not '
          'support that semantic field.',
        );
        continue;
      }

      final modelConfidence =
          field.confidenceBasis == ConfidenceBasis.modelProvided &&
              field.confidence != null
          ? field.confidence!.clamp(0, 1).toDouble()
          : null;
      final confidence =
          modelConfidence ??
          (corroborated && evidence.isNotEmpty
              ? 0.92
              : corroborated
              ? 0.84
              : 0.76);
      accepted[field.name] = ValidatedField(
        name: field.name,
        value: value,
        confidence: confidence,
        confidenceBasis: modelConfidence == null
            ? ConfidenceBasis.validationDerived
            : ConfidenceBasis.modelProvided,
        source: FieldProvenance.machineLocalAI,
        evidence: evidence,
        corroborated: corroborated,
      );
    }

    return ValidatedInterpretation(
      type: type,
      subtype: interpretation.subtype?.trim().isEmpty == true
          ? null
          : interpretation.subtype?.trim(),
      fields: accepted,
      warnings: warnings,
      rejectedFields: rejected,
    );
  }

  static Map<String, Object?> _candidateFields(JsonMap candidate) {
    final raw = candidate['fields'];
    final fields = raw is Map
        ? raw.map((key, value) => MapEntry(key.toString(), value))
        : <String, Object?>{};
    final title = candidate['title'];
    if (title is String) fields['title'] = title;
    return fields;
  }

  static Object? _normalize(String name, Object? raw) {
    if (raw is! String) return raw;
    final value = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value.isEmpty) return null;
    if (_codeFields.contains(name)) return value.toUpperCase();
    if (name == 'url') {
      return value.startsWith('www.') ? 'https://$value' : value;
    }
    return value;
  }

  static bool _valid(String name, Object value, IntelligenceRequest request) {
    if (value is! String || value.length > 240) return false;
    if (_dateFields.contains(name)) {
      final match = RegExp(r'^\d{4}-\d{2}-\d{2}$').firstMatch(value);
      final parsed = DateTime.tryParse(value);
      if (match == null || parsed == null) return false;
      final minYear = request.screenshotCapturedAt.year - 10;
      final maxYear = request.currentTime.year + 20;
      return parsed.year >= minYear && parsed.year <= maxYear;
    }
    if (_timeFields.contains(name)) {
      return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
    }
    if (name == 'price') {
      return RegExp(
        r'^(?:[$€£]\s*)?\d[\d.,]*(?:\s*(?:EUR|USD|GBP))?$',
        caseSensitive: false,
      ).hasMatch(value);
    }
    if (name == 'discount') {
      return RegExp(r'^\d{1,3}(?:[.,]\d+)?\s?%').hasMatch(value);
    }
    if (name == 'url') {
      final uri = Uri.tryParse(value);
      return uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty;
    }
    if (name == 'trackingUrl') {
      final uri = Uri.tryParse(value);
      return uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty;
    }
    if (name == 'latitude') {
      final parsed = double.tryParse(value);
      return parsed != null && parsed >= -90 && parsed <= 90;
    }
    if (name == 'longitude') {
      final parsed = double.tryParse(value);
      return parsed != null && parsed >= -180 && parsed <= 180;
    }
    if (_codeFields.contains(name)) {
      final minimumLength = name == 'trackingNumber' ? 8 : 4;
      final shapeValid =
          value.length >= minimumLength &&
          value.length <= 40 &&
          RegExp(r'^[A-Z0-9_-]+$').hasMatch(value);
      if (!shapeValid) return false;
      if (name == 'couponCode') return RegExp(r'[A-Z]').hasMatch(value);
      return RegExp(r'\d').hasMatch(value);
    }
    return value.length >= 2;
  }

  static String _comparable(Object value) => value
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+', unicode: true), '');

  static bool _evidenceSupports(String name, Object value, String blockText) {
    final comparableValue = _comparable(value);
    final comparableBlock = _comparable(blockText);
    if (comparableValue.isEmpty || comparableBlock.isEmpty) return false;
    if (comparableBlock.contains(comparableValue)) return true;
    if (_dateFields.contains(name)) {
      final date = DateTime.tryParse(value.toString());
      if (date == null) return false;
      final lower = blockText.toLowerCase();
      final hasDay = RegExp('(^|\\D)0?${date.day}(\\D|\$)').hasMatch(lower);
      final hasYear = lower.contains(date.year.toString());
      final monthNames = _monthNames[date.month] ?? const <String>[];
      final hasMonth =
          monthNames.any(lower.contains) ||
          RegExp('(^|\\D)0?${date.month}(\\D|\$)').hasMatch(lower);
      return hasDay && hasMonth && hasYear;
    }
    final words = value
        .toString()
        .toLowerCase()
        .split(RegExp(r'\W+', unicode: true))
        .where((word) => word.length >= 3)
        .toSet();
    if (words.isEmpty) return false;
    final matches = words.where(blockText.toLowerCase().contains).length;
    return matches / words.length >= 0.6;
  }

  static bool _contextSupports(
    String name,
    List<String> evidence,
    IntelligenceRequest request,
  ) {
    final pattern = switch (name) {
      'trackingNumber' || 'trackingUrl' => _trackingContext,
      'couponCode' => _couponContext,
      'orderNumber' => _orderContext,
      _ => null,
    };
    if (pattern == null) return true;
    final evidenceOrders = request.blocks
        .where((block) => evidence.contains(block.id))
        .map((block) => block.order)
        .toList(growable: false);
    return request.blocks.any(
      (block) =>
          block.weight >= _minimumEvidenceWeight &&
          evidenceOrders.any((order) => (block.order - order).abs() <= 2) &&
          pattern.hasMatch(block.text),
    );
  }

  static const _supportedTypes = {
    'event',
    'coupon',
    'place',
    'product',
    'conversationTask',
    'order',
    'reference',
    'other',
  };

  static const _allowedFields = <String, Set<String>>{
    'event': {
      'title',
      'date',
      'time',
      'venue',
      'city',
      'purchaseDate',
      'orderNumber',
      'sector',
      'row',
      'seat',
    },
    'coupon': {'merchant', 'discount', 'couponCode', 'expiryDate'},
    'product': {'productName', 'price', 'merchant', 'url', 'variant'},
    'place': {
      'name',
      'address',
      'city',
      'locality',
      'region',
      'country',
      'latitude',
      'longitude',
    },
    'conversationTask': {'task', 'date', 'time', 'person'},
    'order': {
      'merchant',
      'orderNumber',
      'trackingNumber',
      'purchaseDate',
      'deliveryDate',
      'status',
      'url',
      'trackingUrl',
    },
    'reference': {},
    'other': {},
  };

  static const _dateFields = {
    'date',
    'purchaseDate',
    'expiryDate',
    'deliveryDate',
  };
  static const _timeFields = {'time'};
  static const _codeFields = {'couponCode', 'orderNumber', 'trackingNumber'};
  static const _minimumEvidenceWeight = 0.5;
  static final _trackingContext = RegExp(
    r'\b(track(?:ing)?|shipment|carrier|seguimiento|env[ií]o|transportista|gu[ií]a)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _couponContext = RegExp(
    r'\b(coupon|promo|discount|cup[oó]n|descuento|c[oó]digo)\b',
    caseSensitive: false,
    unicode: true,
  );
  static final _orderContext = RegExp(
    r'\b(order|purchase|pedido|compra|orden)\b',
    caseSensitive: false,
    unicode: true,
  );
  static const _monthNames = <int, List<String>>{
    1: ['jan', 'january', 'enero'],
    2: ['feb', 'february', 'febrero'],
    3: ['mar', 'march', 'marzo'],
    4: ['apr', 'april', 'abril'],
    5: ['may', 'mayo'],
    6: ['jun', 'june', 'junio'],
    7: ['jul', 'july', 'julio'],
    8: ['aug', 'august', 'agosto'],
    9: ['sep', 'september', 'septiembre'],
    10: ['oct', 'october', 'octubre'],
    11: ['nov', 'november', 'noviembre'],
    12: ['dec', 'december', 'diciembre'],
  };
}
