import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';

abstract final class ActionEvidenceThresholds {
  static const minimumFieldConfidence = 0.72;
  static const minimumTrackingLength = 8;
  static const minimumCouponLength = 4;
}

final class ActionGateResult {
  const ActionGateResult.accepted(
    this.value,
    this.reason, {
    this.evidence = const [],
  }) : accepted = true;

  const ActionGateResult.rejected(this.reason)
    : accepted = false,
      value = null,
      evidence = const [];

  final bool accepted;
  final String reason;
  final String? value;
  final List<String> evidence;

  JsonMap toJson({required String action}) => {
    'action': action,
    'accepted': accepted,
    'reason': reason,
    'value': ?value,
    'evidence': evidence,
  };
}

/// Fail-closed validation shared by action policies and debug diagnostics.
final class ActionEvidenceGate {
  const ActionEvidenceGate();

  ActionGateResult trackingNumber(ExtractedObject object) => _field(
    object,
    'trackingNumber',
    validate: (value) =>
        value.length >= ActionEvidenceThresholds.minimumTrackingLength &&
        RegExp(r'^[A-Z0-9_-]+$').hasMatch(value) &&
        RegExp(r'\d').hasMatch(value),
    invalidReason: 'trackingNumber failed tracking-code validation',
  );

  ActionGateResult trackingUrl(ExtractedObject object) => _field(
    object,
    'trackingUrl',
    validate: _validUrl,
    invalidReason: 'trackingUrl is not a valid HTTP(S) URL',
  );

  ActionGateResult couponCode(ExtractedObject object) => _field(
    object,
    'couponCode',
    validate: (value) =>
        value.length >= ActionEvidenceThresholds.minimumCouponLength &&
        RegExp(r'^[A-Z0-9_-]+$').hasMatch(value) &&
        RegExp(r'[A-Z]').hasMatch(value),
    invalidReason: 'couponCode failed coupon-code validation',
  );

  ActionGateResult eventDate(ExtractedObject object) {
    final startsAt = object.structuredData['startsAt'];
    final parsed = startsAt is String ? DateTime.tryParse(startsAt) : null;
    if (parsed == null || parsed.year < 2000 || parsed.year > 2100) {
      return const ActionGateResult.rejected(
        'startsAt is missing or is not a valid date',
      );
    }
    final date = _field(
      object,
      'date',
      validate: (value) => DateTime.tryParse(value) != null,
      invalidReason: 'date failed date validation',
    );
    if (!date.accepted) return date;
    return ActionGateResult.accepted(
      startsAt as String,
      'validated date with evidence',
      evidence: date.evidence,
    );
  }

  ActionGateResult eventTitle(ExtractedObject object) {
    final value = object.title.trim();
    if (value.length < 2 || _genericTitles.contains(value.toLowerCase())) {
      return const ActionGateResult.rejected(
        'title is missing or only a generic fallback',
      );
    }
    final metadata = _metadata(object, 'title');
    if (!_trusted(metadata)) {
      return const ActionGateResult.rejected(
        'title lacks validated provenance/evidence',
      );
    }
    return ActionGateResult.accepted(
      value,
      'validated title with evidence',
      evidence: _evidence(metadata),
    );
  }

  ActionGateResult mapsQuery(ExtractedObject object) {
    final latitude = _field(
      object,
      'latitude',
      validate: (value) {
        final parsed = double.tryParse(value);
        return parsed != null && parsed >= -90 && parsed <= 90;
      },
      invalidReason: 'latitude is invalid',
    );
    final longitude = _field(
      object,
      'longitude',
      validate: (value) {
        final parsed = double.tryParse(value);
        return parsed != null && parsed >= -180 && parsed <= 180;
      },
      invalidReason: 'longitude is invalid',
    );
    if (latitude.accepted && longitude.accepted) {
      return ActionGateResult.accepted(
        '${latitude.value},${longitude.value}',
        'validated coordinates',
        evidence: {...latitude.evidence, ...longitude.evidence}.toList(),
      );
    }

    final address = _field(
      object,
      'address',
      validate: (value) =>
          value.length >= 5 && RegExp(r'[A-Za-zÁÉÍÓÚÜÑ]').hasMatch(value),
      invalidReason: 'address failed address validation',
    );
    if (address.accepted) {
      return ActionGateResult.accepted(
        address.value,
        'validated address',
        evidence: address.evidence,
      );
    }

    final name = _field(
      object,
      'name',
      validate: (value) => value.length >= 2,
      invalidReason: 'place name is invalid',
    );
    final context = _firstAccepted(object, const [
      'locality',
      'city',
      'region',
      'country',
    ]);
    if (name.accepted && context != null) {
      return ActionGateResult.accepted(
        '${name.value}, ${context.value}',
        'validated place name plus location context',
        evidence: {...name.evidence, ...context.evidence}.toList(),
      );
    }
    return const ActionGateResult.rejected(
      'no validated coordinates, address, or place name with location context',
    );
  }

  ActionGateResult reliableField(
    ExtractedObject object,
    String field, {
    bool Function(String value)? validate,
  }) => _field(
    object,
    field,
    validate: validate ?? (value) => value.isNotEmpty,
    invalidReason: '$field failed validation',
  );

  List<JsonMap> diagnosticsFor(ExtractedObject object) =>
      switch (object.type.value) {
        'order' => [
          trackingNumber(object).toJson(action: 'Copy tracking'),
          _oneOf(
            trackingNumber(object),
            trackingUrl(object),
          ).toJson(action: 'Track package'),
        ],
        'coupon' => [couponCode(object).toJson(action: 'Copy code')],
        'event' => [
          _both(
            eventDate(object),
            eventTitle(object),
          ).toJson(action: 'Add to Calendar'),
        ],
        'place' => [mapsQuery(object).toJson(action: 'Open Maps')],
        _ => const [],
      };

  ActionGateResult _field(
    ExtractedObject object,
    String field, {
    required bool Function(String value) validate,
    required String invalidReason,
  }) {
    final raw = object.structuredData[field];
    if (raw is! String || raw.trim().isEmpty) {
      return ActionGateResult.rejected('$field == null');
    }
    final value = raw.trim();
    if (!validate(value)) return ActionGateResult.rejected(invalidReason);
    final metadata = _metadata(object, field);
    if (!_trusted(metadata)) {
      return ActionGateResult.rejected(
        '$field lacks required confidence/evidence',
      );
    }
    return ActionGateResult.accepted(
      value,
      '$field passed validation, confidence, and evidence gates',
      evidence: _evidence(metadata),
    );
  }

  ActionGateResult? _firstAccepted(
    ExtractedObject object,
    List<String> fields,
  ) {
    for (final field in fields) {
      final result = reliableField(object, field);
      if (result.accepted) return result;
    }
    return null;
  }

  static Map<Object?, Object?>? _metadata(
    ExtractedObject object,
    String field,
  ) {
    final all = object.structuredData['_fieldMetadata'];
    if (all is! Map) return null;
    final value = all[field];
    return value is Map ? value : null;
  }

  static bool _trusted(Map<Object?, Object?>? metadata) {
    if (metadata == null) return false;
    final source = metadata['source'];
    if (source == 'userEdited' || source == 'userConfirmed') return true;
    final confidence = metadata['confidence'];
    final evidence = metadata['evidence'];
    return confidence is num &&
        confidence >= ActionEvidenceThresholds.minimumFieldConfidence &&
        evidence is List &&
        evidence.whereType<String>().isNotEmpty;
  }

  static List<String> _evidence(Map<Object?, Object?>? metadata) =>
      (metadata?['evidence'] as List? ?? const []).whereType<String>().toList(
        growable: false,
      );

  static bool _validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static ActionGateResult _oneOf(
    ActionGateResult first,
    ActionGateResult second,
  ) {
    if (first.accepted) return first;
    if (second.accepted) return second;
    return ActionGateResult.rejected('${first.reason}; ${second.reason}');
  }

  static ActionGateResult _both(
    ActionGateResult first,
    ActionGateResult second,
  ) {
    if (first.accepted && second.accepted) {
      return ActionGateResult.accepted(
        first.value,
        '${first.reason}; ${second.reason}',
        evidence: {...first.evidence, ...second.evidence}.toList(),
      );
    }
    return ActionGateResult.rejected(
      [
        if (!first.accepted) first.reason,
        if (!second.accepted) second.reason,
      ].join('; '),
    );
  }

  static const _genericTitles = {
    'event',
    'screenshot',
    'reference',
    'possible product',
    'possible order',
  };
}
