import 'dart:typed_data';

import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/ocr/ocr_evidence_analyzer.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/performance/processing_metrics.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/priority/ai_processing_priority.dart';

enum FastScanState { pending, running, completed, failed }

enum DeepAnalysisState {
  notEvaluated,
  queued,
  running,
  completed,
  skipped,
  deferred,
  failed,
}

final class ProcessingRecord {
  const ProcessingRecord({
    required this.screenshotId,
    required this.assetFingerprint,
    required this.fastState,
    required this.deepState,
    required this.updatedAt,
    this.fastFingerprint,
    this.deepFingerprint,
    this.fastPayload,
    this.aiPriority = 0,
    this.aiEligibilityReasons = const [],
    this.fastTimings = const ProcessingTimings(),
    this.deepTimings = const ProcessingTimings(),
    this.retryCount = 0,
    this.nextRetryAt,
  });

  final String screenshotId;
  final String assetFingerprint;
  final FastScanState fastState;
  final DeepAnalysisState deepState;
  final DateTime updatedAt;
  final String? fastFingerprint;
  final String? deepFingerprint;
  final JsonMap? fastPayload;
  final double aiPriority;
  final List<AIEligibilityReason> aiEligibilityReasons;
  final ProcessingTimings fastTimings;
  final ProcessingTimings deepTimings;
  final int retryCount;
  final DateTime? nextRetryAt;

  bool fastCacheMatches(String fingerprint) =>
      fastState == FastScanState.completed && fastFingerprint == fingerprint;

  bool deepCacheMatches(String fingerprint) =>
      (deepState == DeepAnalysisState.completed ||
          deepState == DeepAnalysisState.skipped) &&
      deepFingerprint == fingerprint;

  ProcessingRecord copyWith({
    String? assetFingerprint,
    FastScanState? fastState,
    DeepAnalysisState? deepState,
    DateTime? updatedAt,
    String? fastFingerprint,
    String? deepFingerprint,
    JsonMap? fastPayload,
    double? aiPriority,
    List<AIEligibilityReason>? aiEligibilityReasons,
    ProcessingTimings? fastTimings,
    ProcessingTimings? deepTimings,
    int? retryCount,
    DateTime? nextRetryAt,
    bool clearDeepFingerprint = false,
    bool clearNextRetryAt = false,
  }) => ProcessingRecord(
    screenshotId: screenshotId,
    assetFingerprint: assetFingerprint ?? this.assetFingerprint,
    fastState: fastState ?? this.fastState,
    deepState: deepState ?? this.deepState,
    updatedAt: updatedAt ?? this.updatedAt,
    fastFingerprint: fastFingerprint ?? this.fastFingerprint,
    deepFingerprint: clearDeepFingerprint
        ? null
        : deepFingerprint ?? this.deepFingerprint,
    fastPayload: fastPayload ?? this.fastPayload,
    aiPriority: aiPriority ?? this.aiPriority,
    aiEligibilityReasons: aiEligibilityReasons ?? this.aiEligibilityReasons,
    fastTimings: fastTimings ?? this.fastTimings,
    deepTimings: deepTimings ?? this.deepTimings,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: clearNextRetryAt ? null : nextRetryAt ?? this.nextRetryAt,
  );
}

final class ProcessingCacheStats {
  const ProcessingCacheStats({
    required this.total,
    required this.fastScanned,
    required this.deepAnalyzed,
    required this.queued,
    required this.deferred,
    required this.failed,
  });

  final int total;
  final int fastScanned;
  final int deepAnalyzed;
  final int queued;
  final int deferred;
  final int failed;
}

final class FastScanResult {
  const FastScanResult({
    required this.screenshot,
    required this.context,
    required this.deterministic,
    required this.eligibility,
    required this.priority,
    required this.timings,
    required this.parserId,
  });

  final Screenshot screenshot;
  final ProcessingContext context;
  final ParseResult deterministic;
  final AIEligibility eligibility;
  final AIProcessingPriority priority;
  final ProcessingTimings timings;
  final String? parserId;

  JsonMap toCacheJson() => {
    'recognizedText': _recognizedTextToJson(context.recognizedText),
    'barcodes': context.barcodes.map(_barcodeToJson).toList(growable: false),
    'classification': {
      'type': context.classification?.type.value,
      'subtype': context.classification?.subtype,
      'confidence': context.classification?.confidence,
      'reasons': context.classification?.reasons ?? const <String>[],
    },
    'parserId': parserId,
  };

  factory FastScanResult.fromCache({
    required Screenshot screenshot,
    required JsonMap payload,
    required List<ExtractedEntity> entities,
    required List<ExtractedObject> objects,
    required ProcessingRecord record,
    OcrEvidenceAnalyzer analyzer = const OcrEvidenceAnalyzer(),
  }) {
    final recognizedText = _recognizedTextFromJson(
      _map(payload['recognizedText']),
    );
    final classificationJson = _map(payload['classification']);
    final classification = ClassificationResult(
      type: ScreenshotType(classificationJson['type'] as String? ?? 'unknown'),
      subtype: classificationJson['subtype'] as String?,
      confidence: (classificationJson['confidence'] as num?)?.toDouble() ?? 0,
      reasons: (classificationJson['reasons'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
    final context = ProcessingContext(
      screenshot: screenshot,
      imageBytes: Uint8List(0),
      recognizedText: recognizedText,
      ocrAnalysis: analyzer.analyze(recognizedText),
      barcodes: (payload['barcodes'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => _barcodeFromJson(_map(value)))
          .toList(growable: false),
      entities: entities,
      classification: classification,
    );
    return FastScanResult(
      screenshot: screenshot,
      context: context,
      deterministic: ParseResult(objects: objects),
      eligibility: AIEligibility(
        needsAI: record.deepState != DeepAnalysisState.skipped,
        reasons: record.aiEligibilityReasons,
      ),
      priority: AIProcessingPriority(
        score: record.aiPriority,
        reasons: const ['restoredFromCache'],
      ),
      timings: record.fastTimings,
      parserId: payload['parserId'] as String?,
    );
  }

  static JsonMap _recognizedTextToJson(RecognizedText value) => {
    'fullText': value.fullText,
    'blocks': [
      for (final block in value.blocks)
        {
          'id': block.id,
          'text': block.text,
          'bounds': block.boundingBox?.toJson(),
          'languages': block.languages,
          'lines': [
            for (final line in block.lines)
              {
                'id': line.id,
                'text': line.text,
                'bounds': line.boundingBox?.toJson(),
                'confidence': line.confidence,
                'languages': line.languages,
              },
          ],
        },
    ],
  };

  static RecognizedText _recognizedTextFromJson(JsonMap value) =>
      RecognizedText(
        fullText: value['fullText'] as String? ?? '',
        blocks: (value['blocks'] as List? ?? const [])
            .whereType<Map>()
            .map((raw) {
              final block = _map(raw);
              return RecognizedTextBlock(
                id: block['id'] as String? ?? '',
                text: block['text'] as String? ?? '',
                boundingBox: _boundsFromJson(block['bounds']),
                languages: (block['languages'] as List? ?? const [])
                    .whereType<String>()
                    .toList(growable: false),
                lines: (block['lines'] as List? ?? const [])
                    .whereType<Map>()
                    .map((rawLine) {
                      final line = _map(rawLine);
                      return RecognizedTextLine(
                        id: line['id'] as String? ?? '',
                        text: line['text'] as String? ?? '',
                        boundingBox: _boundsFromJson(line['bounds']),
                        confidence: (line['confidence'] as num?)?.toDouble(),
                        languages: (line['languages'] as List? ?? const [])
                            .whereType<String>()
                            .toList(growable: false),
                      );
                    })
                    .toList(growable: false),
              );
            })
            .toList(growable: false),
      );

  static JsonMap _barcodeToJson(RecognizedBarcode value) => {
    'rawValue': value.rawValue,
    'displayValue': value.displayValue,
    'format': value.format,
    'valueType': value.valueType,
    'bounds': value.boundingBox?.toJson(),
    'payload': value.payload,
  };

  static RecognizedBarcode _barcodeFromJson(JsonMap value) => RecognizedBarcode(
    rawValue: value['rawValue'] as String? ?? '',
    displayValue: value['displayValue'] as String?,
    format: value['format'] as String? ?? 'unknown',
    valueType: value['valueType'] as String? ?? 'unknown',
    boundingBox: _boundsFromJson(value['bounds']),
    payload: _map(value['payload']),
  );

  static RecognitionBounds? _boundsFromJson(Object? raw) {
    if (raw is! Map) return null;
    final value = _map(raw);
    final left = (value['x'] as num?)?.toDouble();
    final top = (value['y'] as num?)?.toDouble();
    final width = (value['width'] as num?)?.toDouble();
    final height = (value['height'] as num?)?.toDouble();
    if (left == null || top == null || width == null || height == null) {
      return null;
    }
    return RecognitionBounds(
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
    );
  }

  static JsonMap _map(Object? value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : const {};
}
