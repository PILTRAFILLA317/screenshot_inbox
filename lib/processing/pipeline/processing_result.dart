import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/processing/pipeline/fast_scan_result.dart';

final class ProcessingResult {
  const ProcessingResult({
    required this.screenshot,
    required this.entities,
    required this.objects,
    required this.actions,
    required this.lifecycleEvents,
  });

  final Screenshot screenshot;
  final List<ExtractedEntity> entities;
  final List<ExtractedObject> objects;
  final List<SuggestedAction> actions;
  final List<LifecycleEvent> lifecycleEvents;
}

abstract interface class ProcessingStore {
  Future<void> markProcessing(Screenshot screenshot, DateTime at);

  Future<void> persist(ProcessingResult result);

  Future<ProcessingRecord?> findProcessingRecord(String screenshotId);

  Future<Map<String, ProcessingRecord>> findProcessingRecords(
    Iterable<String> screenshotIds,
  );

  Future<void> saveProcessingRecord(ProcessingRecord record);

  Future<void> persistFastScan(FastScanResult result, ProcessingRecord record);

  Future<FastScanResult?> loadFastScan(
    Screenshot screenshot,
    ProcessingRecord record,
  );

  Future<ProcessingCacheStats> processingStats();

  Future<int> clearProcessingCache();

  Future<void> clearProcessingCacheFor(String screenshotId);

  Future<void> markFailed(Screenshot screenshot, DateTime at, Object error);
}
