import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/actions/action_engine.dart';
import 'package:screenshot_inbox/processing/actions/action_policy_registry.dart';
import 'package:screenshot_inbox/processing/actions/default_action_policies.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/lifecycle/default_lifecycle_policies.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy_registry.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/default_screenshot_parsers.dart';
import 'package:screenshot_inbox/processing/parsers/generic_screenshot_parser.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
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
    expect(result.screenshot.processingVersion, 2);
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
}

final class _FakePhotoRepository implements PhotoRepository {
  @override
  Future<PhotoPermissionState> currentPermission() async =>
      PhotoPermissionState.authorized;

  @override
  Future<Set<String>> deleteAssets(List<String> assetIds) async =>
      assetIds.toSet();

  @override
  Future<Uint8List?> getProcessingImage(String assetId) async =>
      Uint8List.fromList([1, 2, 3]);

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

  @override
  Future<void> close() async {}

  @override
  Future<RecognizedText> recognize(Uint8List imageBytes) async =>
      RecognizedText(
        fullText: text,
        blocks: [RecognizedTextBlock(id: 'B01', text: text, lines: const [])],
      );
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
