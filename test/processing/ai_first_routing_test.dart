import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/infrastructure/intelligence/fake_intelligence_provider.dart';
import 'package:screenshot_inbox/processing/actions/action_engine.dart';
import 'package:screenshot_inbox/processing/actions/action_policy_registry.dart';
import 'package:screenshot_inbox/processing/actions/default_action_policies.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/discovery/screenshot_discovery_coordinator.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/lifecycle/default_lifecycle_policies.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy_registry.dart';
import 'package:screenshot_inbox/processing/intelligence/intelligence_enricher.dart';
import 'package:screenshot_inbox/processing/intelligence/interpretation_validator.dart';
import 'package:screenshot_inbox/processing/image/processing_image_policy.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/generic_screenshot_parser.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/performance/processing_metrics.dart';
import 'package:screenshot_inbox/processing/pipeline/fast_scan_result.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/screenshot_processing_pipeline.dart';
import 'package:screenshot_inbox/processing/scheduling/processing_scheduler.dart';

import '../support/fixtures.dart';

void main() {
  test(
    'new other/generic screenshot reaches AI, persists AI type, and caches',
    () async {
      final provider = FakeIntelligenceProvider(result: _productResult);
      final harness = _Harness(
        provider: provider,
        batches: [
          [_asset],
          [_asset],
        ],
      );
      addTearDown(harness.dispose);

      await harness.run();

      expect(harness.store.fastScans.single.eligibility.needsAI, isFalse);
      expect(harness.store.fastScans.single.parserId, 'generic.v1');
      expect(provider.availabilityChecks, 1);
      expect(provider.requests, hasLength(1));
      expect(provider.requests.single.imageBytes, isNotEmpty);
      expect(provider.requests.single.blocks, hasLength(3));
      expect(provider.requests.single.typeHint, 'other');
      expect(harness.store.persisted, hasLength(1));
      expect(
        harness.store.persisted.single.screenshot.processingStatus,
        ScreenshotProcessingStatus.processed,
      );
      expect(
        harness.store.persisted.single.screenshot.primaryType,
        ScreenshotType.product,
      );
      expect(
        harness.store.persisted.single.objects.single.type.value,
        'product',
      );
      expect(
        harness.store.records.values.single.deepState,
        DeepAnalysisState.completed,
      );

      await harness.runAgain();

      expect(provider.requests, hasLength(1));
      expect(provider.availabilityChecks, 1);
    },
  );

  test('unavailable provider completes with deterministic fallback', () async {
    final provider = FakeIntelligenceProvider(
      state: const IntelligenceAvailability(
        state: IntelligenceAvailabilityState.unsupportedDevice,
        provider: 'fake-local',
      ),
    );
    final harness = _Harness(
      provider: provider,
      batches: [
        [_asset],
      ],
    );
    addTearDown(harness.dispose);

    await harness.run();

    expect(provider.availabilityChecks, 1);
    expect(provider.requests, isEmpty);
    expect(harness.store.persisted, hasLength(1));
    expect(
      harness.store.persisted.single.screenshot.processingStatus,
      ScreenshotProcessingStatus.processed,
    );
    expect(harness.store.persisted.single.objects.single.type.value, 'other');
    expect(
      harness.store.records.values.single.deepState,
      DeepAnalysisState.skipped,
    );
  });

  test('temporary unavailability defers AI without failing fallback', () async {
    final provider = FakeIntelligenceProvider(
      state: const IntelligenceAvailability(
        state: IntelligenceAvailabilityState.modelNotReady,
        provider: 'geminiNano',
      ),
    );
    final harness = _Harness(
      provider: provider,
      batches: [
        [_asset],
      ],
    );
    addTearDown(harness.dispose);

    await harness.run();

    expect(provider.requests, isEmpty);
    expect(
      harness.store.persisted.single.screenshot.processingStatus,
      ScreenshotProcessingStatus.processed,
    );
    expect(
      harness.store.records.values.single.deepState,
      DeepAnalysisState.deferred,
    );
    expect(harness.store.records.values.single.deepFingerprint, isNull);
  });

  test('provider errors fall back and do not stop the next deep job', () async {
    final provider = FakeIntelligenceProvider(error: StateError('model died'));
    final second = PhotoAsset(
      id: 'asset-2',
      createdAt: _now,
      width: 1179,
      height: 2556,
    );
    final harness = _Harness(
      provider: provider,
      batches: [
        [_asset, second],
      ],
    );
    addTearDown(harness.dispose);

    await harness.run();

    expect(provider.requests, hasLength(2));
    expect(harness.store.persisted, hasLength(2));
    expect(
      harness.store.persisted.every(
        (result) =>
            result.screenshot.processingStatus ==
            ScreenshotProcessingStatus.processed,
      ),
      isTrue,
    );
    expect(
      harness.store.records.values.map((record) => record.deepState),
      everyElement(DeepAnalysisState.failed),
    );
    expect(
      harness.store.records.values.map((record) => record.retryCount),
      everyElement(1),
    );
  });
}

final _now = DateTime.utc(2026, 8, 19, 12);
final _asset = PhotoAsset(
  id: 'asset-1',
  createdAt: _now,
  width: 1179,
  height: 2556,
);

const _productResult = IntelligenceResult(
  provider: 'geminiNano',
  providerVersion: 'test',
  imageInput: true,
  ocrInput: true,
  duration: Duration(milliseconds: 12),
  interpretations: [
    IntelligenceInterpretation(
      type: 'product',
      subtype: 'retail_product',
      fields: [
        IntelligenceField(
          name: 'productName',
          value: 'Nike Air Max',
          evidence: ['B01'],
        ),
        IntelligenceField(name: 'price', value: '€149', evidence: ['B02']),
      ],
    ),
  ],
);

final class _Harness {
  _Harness({
    required FakeIntelligenceProvider provider,
    required List<List<PhotoAsset>> batches,
  }) : photos = _PhotoRepository(batches),
       screenshots = _ScreenshotRepository(),
       clock = FixedClock(_now),
       ids = SequenceIdGenerator() {
    store = _ProcessingStore(screenshots);
    final pipeline = ScreenshotProcessingPipeline(
      photos: photos,
      textRecognition: const _TextRecognition(),
      barcodeRecognition: const _BarcodeRecognition(),
      entityExtractor: RegexEntityExtractor(ids),
      classifier: const _OtherClassifier(),
      parsers: ParserRegistry([GenericScreenshotParser(ids, clock)]),
      actions: ActionEngine(
        ActionPolicyRegistry(const [SaveObjectActionPolicy()]),
        ids,
        clock,
      ),
      lifecycle: LifecycleEngine(
        LifecyclePolicyRegistry(const [DefaultLifecyclePolicy()]),
        clock,
      ),
      store: store,
      clock: clock,
      ids: ids,
      metrics: ProcessingMetricsCollector(),
      intelligence: IntelligenceEnricher(
        provider: provider,
        validator: const InterpretationValidator(),
        policy: IntelligenceUsagePolicy.actionableTypes,
        clock: clock,
        ids: ids,
        locale: () => 'en_GB',
        timezone: () => 'Europe/Madrid',
      ),
    );
    coordinator = ScreenshotDiscoveryCoordinator(
      photos: photos,
      screenshots: screenshots,
      pipeline: pipeline,
      store: store,
      scheduler: ProcessingScheduler(resources: const _ResourceMonitor()),
      metrics: ProcessingMetricsCollector(),
      clock: clock,
      ids: ids,
    );
  }

  final _PhotoRepository photos;
  final _ScreenshotRepository screenshots;
  final FixedClock clock;
  final SequenceIdGenerator ids;
  late final _ProcessingStore store;
  late final ScreenshotDiscoveryCoordinator coordinator;

  Future<void> run() async {
    final completed = coordinator.states.firstWhere(
      (state) => state.phase == DiscoveryPhase.complete,
    );
    await coordinator.start();
    await completed.timeout(const Duration(seconds: 2));
  }

  Future<void> runAgain() async {
    await pumpEventQueue();
    final completed = coordinator.states.firstWhere(
      (state) => state.phase == DiscoveryPhase.complete,
    );
    await coordinator.restart();
    await completed.timeout(const Duration(seconds: 2));
  }

  Future<void> dispose() => coordinator.dispose();
}

final class _PhotoRepository implements PhotoRepository {
  const _PhotoRepository(this.batches);

  final List<List<PhotoAsset>> batches;

  @override
  Future<PhotoPermissionState> currentPermission() async =>
      PhotoPermissionState.authorized;

  @override
  Future<Set<String>> deleteAssets(List<String> assetIds) async =>
      assetIds.toSet();

  @override
  Future<ProcessingImageLoad?> getProcessingImage(
    String assetId, {
    ProcessingImagePurpose purpose = ProcessingImagePurpose.ocr,
  }) async => ProcessingImageLoad(
    bytes: Uint8List.fromList([1, 2, 3]),
    width: 590,
    height: 1280,
    assetLoadingDuration: Duration.zero,
    generationDuration: Duration.zero,
  );

  @override
  Future<List<PhotoAsset>> getScreenshots({
    DateTime? after,
    int? limit,
  }) async => batches.expand((batch) => batch).toList(growable: false);

  @override
  Stream<List<PhotoAsset>> getScreenshotBatches({int batchSize = 50}) =>
      Stream.fromIterable(batches);

  @override
  Future<Uint8List?> getThumbnail(String assetId) async => null;

  @override
  Future<void> openSettings() async {}

  @override
  Future<PhotoPermissionState> requestPermission() async =>
      PhotoPermissionState.authorized;
}

final class _ScreenshotRepository implements ScreenshotRepository {
  final Map<String, Screenshot> _values = {};

  @override
  Future<int> countByLifecycleStates(Set<LifecycleState> states) async =>
      _values.values
          .where((item) => states.contains(item.currentLifecycleState))
          .length;

  @override
  Future<List<Screenshot>> findAll() async =>
      _values.values.toList(growable: false);

  @override
  Future<Screenshot?> findByAssetId(String assetId) async =>
      _values.values.where((item) => item.assetId == assetId).firstOrNull;

  @override
  Future<Map<String, Screenshot>> findByAssetIds(
    Iterable<String> assetIds,
  ) async {
    final requested = assetIds.toSet();
    return {
      for (final item in _values.values)
        if (requested.contains(item.assetId)) item.assetId: item,
    };
  }

  @override
  Future<Screenshot?> findById(String id) async => _values[id];

  @override
  Future<List<Screenshot>> findByProcessingStatuses(
    Set<ScreenshotProcessingStatus> statuses,
  ) async => _values.values
      .where((item) => statuses.contains(item.processingStatus))
      .toList(growable: false);

  @override
  Future<void> save(Screenshot screenshot) async {
    _values[screenshot.id] = screenshot;
  }

  @override
  Future<void> setLifecycleState(String id, LifecycleState state) async {
    final screenshot = _values[id];
    if (screenshot != null) {
      _values[id] = screenshot.copyWith(currentLifecycleState: state);
    }
  }

  @override
  Stream<List<Screenshot>> watchRecent({int limit = 20}) =>
      Stream.value(_values.values.take(limit).toList(growable: false));
}

final class _ProcessingStore implements ProcessingStore {
  _ProcessingStore(this.screenshots);

  final _ScreenshotRepository screenshots;
  final Map<String, ProcessingRecord> records = {};
  final Map<String, FastScanResult> _fastScans = {};
  final List<ProcessingResult> persisted = [];

  List<FastScanResult> get fastScans =>
      _fastScans.values.toList(growable: false);

  @override
  Future<int> clearProcessingCache() async {
    final count = records.length;
    records.clear();
    _fastScans.clear();
    return count;
  }

  @override
  Future<void> clearProcessingCacheFor(String screenshotId) async {
    records.remove(screenshotId);
    _fastScans.remove(screenshotId);
  }

  @override
  Future<ProcessingRecord?> findProcessingRecord(String screenshotId) async =>
      records[screenshotId];

  @override
  Future<Map<String, ProcessingRecord>> findProcessingRecords(
    Iterable<String> screenshotIds,
  ) async {
    final requested = screenshotIds.toSet();
    return {
      for (final entry in records.entries)
        if (requested.contains(entry.key)) entry.key: entry.value,
    };
  }

  @override
  Future<FastScanResult?> loadFastScan(
    Screenshot screenshot,
    ProcessingRecord record,
  ) async => _fastScans[screenshot.id];

  @override
  Future<void> markFailed(
    Screenshot screenshot,
    DateTime at,
    Object error,
  ) async {
    await screenshots.save(
      screenshot.copyWith(
        processingStatus: ScreenshotProcessingStatus.failed,
        lastProcessedAt: at,
      ),
    );
  }

  @override
  Future<void> markProcessing(Screenshot screenshot, DateTime at) async {
    await screenshots.save(
      screenshot.copyWith(
        processingStatus: ScreenshotProcessingStatus.processing,
        lastProcessedAt: at,
      ),
    );
  }

  @override
  Future<void> persist(ProcessingResult result) async {
    persisted.add(result);
    await screenshots.save(result.screenshot);
  }

  @override
  Future<void> persistFastScan(
    FastScanResult result,
    ProcessingRecord record,
  ) async {
    _fastScans[result.screenshot.id] = result;
    records[record.screenshotId] = record;
    await screenshots.save(result.screenshot);
  }

  @override
  Future<ProcessingCacheStats> processingStats() async => ProcessingCacheStats(
    total: records.length,
    fastScanned: records.values
        .where((item) => item.fastState == FastScanState.completed)
        .length,
    deepAnalyzed: records.values
        .where((item) => item.deepState == DeepAnalysisState.completed)
        .length,
    queued: records.values
        .where((item) => item.deepState == DeepAnalysisState.queued)
        .length,
    deferred: records.values
        .where((item) => item.deepState == DeepAnalysisState.deferred)
        .length,
    failed: records.values
        .where((item) => item.deepState == DeepAnalysisState.failed)
        .length,
  );

  @override
  Future<void> saveProcessingRecord(ProcessingRecord record) async {
    records[record.screenshotId] = record;
  }
}

final class _TextRecognition implements TextRecognitionService {
  const _TextRecognition();

  @override
  Future<void> close() async {}

  @override
  Future<RecognizedText> recognize(Uint8List imageBytes) async =>
      const RecognizedText(
        fullText: 'Nike Air Max\n€149\nSize 42',
        blocks: [
          RecognizedTextBlock(id: 'B01', text: 'Nike Air Max', lines: []),
          RecognizedTextBlock(id: 'B02', text: '€149', lines: []),
          RecognizedTextBlock(id: 'B03', text: 'Size 42', lines: []),
        ],
      );
}

final class _BarcodeRecognition implements BarcodeRecognitionService {
  const _BarcodeRecognition();

  @override
  Future<void> close() async {}

  @override
  Future<List<RecognizedBarcode>> recognize(Uint8List imageBytes) async =>
      const [];
}

final class _OtherClassifier implements ScreenshotClassifier {
  const _OtherClassifier();

  @override
  Future<ClassificationResult> classify(ProcessingContext context) async =>
      const ClassificationResult(
        type: ScreenshotType.other,
        subtype: 'other.unclassified',
        confidence: 0.2,
      );
}

final class _ResourceMonitor implements DeviceResourceMonitor {
  const _ResourceMonitor();

  @override
  Future<DeviceResourceState> snapshot() async =>
      const DeviceResourceState(thermal: DeviceThermalState.nominal);
}
