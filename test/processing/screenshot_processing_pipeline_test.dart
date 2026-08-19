import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';
import 'package:screenshot_inbox/infrastructure/intelligence/fake_intelligence_provider.dart';
import 'package:screenshot_inbox/processing/actions/action_engine.dart';
import 'package:screenshot_inbox/processing/actions/action_policy_registry.dart';
import 'package:screenshot_inbox/processing/actions/default_action_policies.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/lifecycle/default_lifecycle_policies.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy_registry.dart';
import 'package:screenshot_inbox/processing/image/processing_image_policy.dart';
import 'package:screenshot_inbox/processing/intelligence/intelligence_enricher.dart';
import 'package:screenshot_inbox/processing/intelligence/interpretation_validator.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/default_screenshot_parsers.dart';
import 'package:screenshot_inbox/processing/parsers/generic_screenshot_parser.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/pipeline/fast_scan_result.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/screenshot_processing_pipeline.dart';

import '../support/fixtures.dart';
import '../support/text_corpus.dart';

void main() {
  test('processes a simulated screenshot through every stage', () async {
    final clock = FixedClock(DateTime.utc(2026, 8, 18, 12));
    final ids = SequenceIdGenerator();
    final store = _FakeProcessingStore();
    final pipeline = ScreenshotProcessingPipeline(
      photos: _FakePhotoRepository(),
      textRecognition: _FakeTextRecognition(),
      barcodeRecognition: _FakeBarcodeRecognition(),
      entityExtractor: RegexEntityExtractor(ids),
      classifier: _EventClassifier(),
      parsers: ParserRegistry([GenericScreenshotParser(ids, clock)]),
      actions: ActionEngine(
        ActionPolicyRegistry(const [
          UrlActionPolicy(),
          SaveObjectActionPolicy(),
        ]),
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
    );

    final result = await pipeline.process(screenshotFixture());

    expect(store.markedProcessing, isTrue);
    expect(store.persisted, same(result));
    expect(
      result.screenshot.processingStatus,
      ScreenshotProcessingStatus.processed,
    );
    expect(result.screenshot.processingVersion, 3);
    expect(result.screenshot.primaryType, ScreenshotType.reference);
    expect(result.screenshot.currentLifecycleState.name, 'actionable');
    expect(
      result.entities.map((entity) => entity.type.value),
      containsAll(['url', 'date', 'qr']),
    );
    expect(result.objects.single.subtype, 'reference.generic');
    expect(result.actions, hasLength(1));
    expect(result.lifecycleEvents, hasLength(1));
  });

  test('runs the real deterministic coupon stack end to end', () async {
    final clock = FixedClock(DateTime.utc(2026, 8, 21, 12));
    final ids = SequenceIdGenerator();
    final store = _FakeProcessingStore();
    final pipeline = ScreenshotProcessingPipeline(
      photos: _FakePhotoRepository(),
      textRecognition: _FakeTextRecognition(couponEnglish),
      barcodeRecognition: _FakeBarcodeRecognition(),
      entityExtractor: RegexEntityExtractor(ids),
      classifier: RuleBasedScreenshotClassifier(),
      parsers: ParserRegistry([
        CouponParser(ids, clock),
        GenericScreenshotParser(ids, clock),
      ]),
      actions: ActionEngine(
        ActionPolicyRegistry([
          CouponActionPolicy(clock),
          const SaveObjectActionPolicy(),
        ]),
        ids,
        clock,
      ),
      lifecycle: LifecycleEngine(
        LifecyclePolicyRegistry(const [
          CouponLifecyclePolicy(),
          DefaultLifecyclePolicy(),
        ]),
        clock,
      ),
      store: store,
      clock: clock,
      ids: ids,
    );

    final result = await pipeline.process(screenshotFixture());

    expect(result.screenshot.primaryType, ScreenshotType.coupon);
    expect(result.screenshot.currentLifecycleState.name, 'expiring');
    expect(result.objects.single.structuredData['couponCode'], 'RUN20');
    expect(
      result.actions.map((action) => action.type.value),
      containsAll(['copy', 'reminder']),
    );
  });

  test('same asset and versions restore cache without OCR or AI', () async {
    final clock = FixedClock(DateTime.utc(2026, 8, 21, 12));
    final ids = SequenceIdGenerator();
    final store = _FakeProcessingStore();
    final text = _FakeTextRecognition();
    final provider = FakeIntelligenceProvider();
    final pipeline = ScreenshotProcessingPipeline(
      photos: _FakePhotoRepository(),
      textRecognition: text,
      barcodeRecognition: _FakeBarcodeRecognition(),
      entityExtractor: RegexEntityExtractor(ids),
      classifier: _EventClassifier(),
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
      intelligence: IntelligenceEnricher(
        provider: provider,
        validator: const InterpretationValidator(),
        policy: IntelligenceUsagePolicy.alwaysForSupportedTypes,
        clock: clock,
        ids: ids,
      ),
    );
    final screenshot = screenshotFixture();

    final first = await pipeline.process(screenshot);
    final restored = await pipeline.restoreFastScan(first.screenshot);

    expect(restored, isNotNull);
    expect(text.recognizeCount, 1);
    expect(provider.requests, hasLength(1));
  });
}

final class _FakePhotoRepository implements PhotoRepository {
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
    width: 100,
    height: 200,
    assetLoadingDuration: Duration.zero,
    generationDuration: Duration.zero,
  );

  @override
  Future<List<PhotoAsset>> getScreenshots({
    DateTime? after,
    int? limit,
  }) async => const [];

  @override
  Stream<List<PhotoAsset>> getScreenshotBatches({int batchSize = 50}) =>
      const Stream.empty();

  @override
  Future<void> openSettings() async {}

  @override
  Future<Uint8List?> getThumbnail(String assetId) async => null;

  @override
  Future<PhotoPermissionState> requestPermission() async =>
      PhotoPermissionState.authorized;
}

final class _FakeTextRecognition implements TextRecognitionService {
  _FakeTextRecognition([
    this.text = 'Event ticket 2026-08-22 https://example.com',
  ]);

  final String text;
  var recognizeCount = 0;

  @override
  Future<void> close() async {}

  @override
  Future<RecognizedText> recognize(Uint8List imageBytes) async {
    recognizeCount++;
    return RecognizedText(
      fullText: text,
      blocks: [RecognizedTextBlock(id: 'B01', text: text, lines: const [])],
    );
  }
}

final class _FakeBarcodeRecognition implements BarcodeRecognitionService {
  @override
  Future<void> close() async {}

  @override
  Future<List<RecognizedBarcode>> recognize(Uint8List imageBytes) async =>
      const [RecognizedBarcode(rawValue: 'PASS-123', format: 'qrCode')];
}

final class _EventClassifier implements ScreenshotClassifier {
  @override
  Future<ClassificationResult> classify(ProcessingContext context) async =>
      const ClassificationResult(
        type: ScreenshotType.event,
        subtype: 'event.generic',
        confidence: 0.9,
      );
}

final class _FakeProcessingStore implements ProcessingStore {
  bool markedProcessing = false;
  ProcessingResult? persisted;
  ProcessingRecord? record;
  FastScanResult? fastScan;

  @override
  Future<int> clearProcessingCache() async => 0;

  @override
  Future<void> clearProcessingCacheFor(String screenshotId) async {}

  @override
  Future<ProcessingRecord?> findProcessingRecord(String screenshotId) async =>
      record;

  @override
  Future<Map<String, ProcessingRecord>> findProcessingRecords(
    Iterable<String> screenshotIds,
  ) async => record == null ? const {} : {record!.screenshotId: record!};

  @override
  Future<FastScanResult?> loadFastScan(
    Screenshot screenshot,
    ProcessingRecord record,
  ) async => fastScan;

  @override
  Future<void> persistFastScan(
    FastScanResult result,
    ProcessingRecord record,
  ) async {
    fastScan = result;
    this.record = record;
  }

  @override
  Future<ProcessingCacheStats> processingStats() async =>
      const ProcessingCacheStats(
        total: 0,
        fastScanned: 0,
        deepAnalyzed: 0,
        queued: 0,
        deferred: 0,
        failed: 0,
      );

  @override
  Future<void> saveProcessingRecord(ProcessingRecord record) async {
    this.record = record;
  }

  @override
  Future<void> markFailed(
    Screenshot screenshot,
    DateTime at,
    Object error,
  ) async {}

  @override
  Future<void> markProcessing(Screenshot screenshot, DateTime at) async {
    markedProcessing = true;
  }

  @override
  Future<void> persist(ProcessingResult result) async {
    persisted = result;
  }
}
