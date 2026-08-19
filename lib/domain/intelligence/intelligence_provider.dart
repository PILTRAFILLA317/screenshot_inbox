import 'package:screenshot_inbox/core/utils/json_types.dart';

enum IntelligenceAvailabilityState {
  available,
  temporarilyUnavailable,
  unsupportedDevice,
  disabled,
  modelNotReady,
  unknown,
}

enum IntelligenceUsagePolicy {
  disabled,
  lowConfidenceOnly,
  actionableTypes,
  alwaysForSupportedTypes,
}

enum FieldProvenance {
  machineDeterministic,
  machineLocalAI,
  userConfirmed,
  userEdited,
}

/// Confidence is validation-derived unless a platform explicitly reports a
/// calibrated value. Local foundation models currently do not expose one.
enum ConfidenceBasis { modelProvided, heuristic, validationDerived }

final class IntelligenceAvailability {
  const IntelligenceAvailability({
    required this.state,
    required this.provider,
    this.providerVersion,
    this.reason,
  });

  final IntelligenceAvailabilityState state;
  final String provider;
  final String? providerVersion;
  final String? reason;

  bool get isAvailable => state == IntelligenceAvailabilityState.available;

  JsonMap toJson() => {
    'state': state.name,
    'provider': provider,
    'providerVersion': ?providerVersion,
    'reason': ?reason,
  };
}

final class OcrBlockInput {
  const OcrBlockInput({
    required this.id,
    required this.text,
    required this.order,
    this.bounds,
    this.lines = const [],
  });

  final String id;
  final String text;
  final int order;
  final JsonMap? bounds;
  final List<JsonMap> lines;

  JsonMap toJson() => {
    'id': id,
    'text': text,
    'order': order,
    'bounds': ?bounds,
    'lines': lines,
  };
}

final class IntelligenceRequest {
  const IntelligenceRequest({
    required this.screenshotCapturedAt,
    required this.currentTime,
    required this.locale,
    required this.timezone,
    required this.blocks,
    required this.entities,
    required this.deterministicCandidates,
    this.typeHint,
    this.interpretationVersion = 1,
  });

  final String? typeHint;
  final DateTime screenshotCapturedAt;
  final DateTime currentTime;
  final String locale;
  final String timezone;
  final List<OcrBlockInput> blocks;
  final List<JsonMap> entities;
  final List<JsonMap> deterministicCandidates;
  final int interpretationVersion;

  JsonMap toJson() => {
    'typeHint': ?typeHint,
    'screenshotCapturedAt': screenshotCapturedAt.toIso8601String(),
    'currentTime': currentTime.toIso8601String(),
    'locale': locale,
    'timezone': timezone,
    'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
    'entities': entities,
    'deterministicCandidates': deterministicCandidates,
    'interpretationVersion': interpretationVersion,
  };
}

final class IntelligenceField {
  const IntelligenceField({
    required this.name,
    required this.value,
    this.evidence = const [],
    this.confidence,
    this.confidenceBasis,
  });

  final String name;
  final Object? value;
  final List<String> evidence;
  final double? confidence;
  final ConfidenceBasis? confidenceBasis;

  factory IntelligenceField.fromJson(JsonMap json) {
    final rawConfidence = json['confidence'];
    final rawBasis = json['confidenceBasis'];
    return IntelligenceField(
      name: json['name'] as String? ?? '',
      value: json['value'],
      evidence: (json['evidence'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      confidence: rawConfidence is num ? rawConfidence.toDouble() : null,
      confidenceBasis: rawBasis is String
          ? ConfidenceBasis.values
                .where((basis) => basis.name == rawBasis)
                .firstOrNull
          : null,
    );
  }

  JsonMap toJson() => {
    'name': name,
    'value': value,
    'evidence': evidence,
    'confidence': ?confidence,
    'confidenceBasis': ?confidenceBasis?.name,
  };
}

final class IntelligenceInterpretation {
  const IntelligenceInterpretation({
    required this.type,
    required this.fields,
    this.subtype,
  });

  final String type;
  final String? subtype;
  final List<IntelligenceField> fields;

  factory IntelligenceInterpretation.fromJson(JsonMap json) =>
      IntelligenceInterpretation(
        type: json['type'] as String? ?? '',
        subtype: json['subtype'] as String?,
        fields: (json['fields'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (field) => IntelligenceField.fromJson(
                field.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList(growable: false),
      );

  JsonMap toJson() => {
    'type': type,
    'subtype': ?subtype,
    'fields': fields.map((field) => field.toJson()).toList(growable: false),
  };
}

final class IntelligenceResult {
  const IntelligenceResult({
    required this.provider,
    required this.interpretations,
    required this.duration,
    this.providerVersion,
  });

  final String provider;
  final String? providerVersion;
  final List<IntelligenceInterpretation> interpretations;
  final Duration duration;

  factory IntelligenceResult.fromJson(JsonMap json) => IntelligenceResult(
    provider: json['provider'] as String? ?? 'local-unknown',
    providerVersion: json['providerVersion'] as String?,
    interpretations: (json['interpretations'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => IntelligenceInterpretation.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false),
    duration: Duration(
      milliseconds: (json['durationMs'] as num?)?.round() ?? 0,
    ),
  );

  JsonMap toJson() => {
    'provider': provider,
    'providerVersion': ?providerVersion,
    'durationMs': duration.inMilliseconds,
    'interpretations': interpretations
        .map((item) => item.toJson())
        .toList(growable: false),
  };
}

abstract interface class IntelligenceProvider {
  Future<IntelligenceResult> interpret(IntelligenceRequest request);

  Future<IntelligenceAvailability> availability();
}
