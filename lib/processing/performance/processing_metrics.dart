import 'package:screenshot_inbox/core/debug/local_debug_log.dart';

final class ProcessingTimings {
  const ProcessingTimings({this.values = const {}});

  final Map<String, int> values;

  int operator [](String key) => values[key] ?? 0;

  ProcessingTimings merged(Map<String, int> other) =>
      ProcessingTimings(values: Map.unmodifiable({...values, ...other}));

  Map<String, Object?> toJson() => Map.unmodifiable(values);
}

final class ProcessingSessionMetrics {
  const ProcessingSessionMetrics({
    required this.screenshotsDiscovered,
    required this.fastScansCompleted,
    required this.aiScansCompleted,
    required this.screenshotsSkipped,
    required this.screenshotsCached,
    required this.failures,
    required this.averageOcrMs,
    required this.averageAiMs,
    required this.p50AiMs,
    required this.p95AiMs,
  });

  const ProcessingSessionMetrics.empty()
    : this(
        screenshotsDiscovered: 0,
        fastScansCompleted: 0,
        aiScansCompleted: 0,
        screenshotsSkipped: 0,
        screenshotsCached: 0,
        failures: 0,
        averageOcrMs: 0,
        averageAiMs: 0,
        p50AiMs: 0,
        p95AiMs: 0,
      );

  final int screenshotsDiscovered;
  final int fastScansCompleted;
  final int aiScansCompleted;
  final int screenshotsSkipped;
  final int screenshotsCached;
  final int failures;
  final double averageOcrMs;
  final double averageAiMs;
  final int p50AiMs;
  final int p95AiMs;
}

/// Local, in-memory session telemetry. It logs IDs and durations only; OCR,
/// entities, model output, and image bytes are intentionally not accepted.
final class ProcessingMetricsCollector {
  final List<int> _ocr = [];
  final List<int> _ai = [];
  var _discovered = 0;
  var _fast = 0;
  var _deep = 0;
  var _skipped = 0;
  var _cached = 0;
  var _failures = 0;

  ProcessingSessionMetrics get snapshot => ProcessingSessionMetrics(
    screenshotsDiscovered: _discovered,
    fastScansCompleted: _fast,
    aiScansCompleted: _deep,
    screenshotsSkipped: _skipped,
    screenshotsCached: _cached,
    failures: _failures,
    averageOcrMs: _average(_ocr),
    averageAiMs: _average(_ai),
    p50AiMs: _percentile(_ai, 0.50),
    p95AiMs: _percentile(_ai, 0.95),
  );

  void discovered(int count) => _discovered += count;
  void cached() => _cached++;
  void skipped() => _skipped++;
  void failed() => _failures++;

  void fastCompleted(String screenshotId, ProcessingTimings timings) {
    _fast++;
    _ocr.add(timings['ocrMs']);
    _log('processing.fast_scan.completed', screenshotId, timings);
  }

  void deepCompleted(String screenshotId, ProcessingTimings timings) {
    _deep++;
    _ai.add(timings['localAiMs']);
    _log('processing.deep_scan.completed', screenshotId, timings);
  }

  static void _log(
    String name,
    String screenshotId,
    ProcessingTimings timings,
  ) {
    LocalDebugLog.event(
      name,
      metadata: {'screenshotId': screenshotId, ...timings.toJson()},
    );
  }

  static double _average(List<int> values) => values.isEmpty
      ? 0
      : values.reduce((left, right) => left + right) / values.length;

  static int _percentile(List<int> values, double percentile) {
    if (values.isEmpty) return 0;
    final sorted = values.toList()..sort();
    final index = ((sorted.length - 1) * percentile).ceil();
    return sorted[index];
  }
}
