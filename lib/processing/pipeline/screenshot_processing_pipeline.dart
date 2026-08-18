import 'package:screenshot_inbox/core/errors/app_exception.dart';
import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/processing/actions/action_engine.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';

final class ScreenshotProcessingPipeline {
  ScreenshotProcessingPipeline({
    required this.photos,
    required this.textRecognition,
    required this.barcodeRecognition,
    required this.entityExtractor,
    required this.classifier,
    required this.parsers,
    required this.actions,
    required this.lifecycle,
    required this.store,
    required this.clock,
    required this.ids,
  });

  final PhotoRepository photos;
  final TextRecognitionService textRecognition;
  final BarcodeRecognitionService barcodeRecognition;
  final EntityExtractor entityExtractor;
  final ScreenshotClassifier classifier;
  final ParserRegistry parsers;
  final ActionEngine actions;
  final LifecycleEngine lifecycle;
  final ProcessingStore store;
  final Clock clock;
  final IdGenerator ids;

  Future<ProcessingResult> process(Screenshot screenshot) async {
    final startedAt = clock.now();
    await store.markProcessing(screenshot, startedAt);

    try {
      final imageBytes = await photos.getProcessingImage(screenshot.assetId);
      if (imageBytes == null || imageBytes.isEmpty) {
        throw const ScreenshotProcessingException(
          'Photos returned no processable image data.',
        );
      }

      var context = ProcessingContext(
        screenshot: screenshot,
        imageBytes: imageBytes,
      );
      final recognizedText = await textRecognition.recognize(imageBytes);
      context = context.copyWith(ocrText: recognizedText.text);
      final barcodes = await barcodeRecognition.recognize(imageBytes);
      context = context.copyWith(barcodes: barcodes);
      final entities = await entityExtractor.extract(context);
      context = context.copyWith(entities: entities);
      final classification = await classifier.classify(context);
      context = context.copyWith(classification: classification);
      final parseResult = await parsers.parse(context);
      final suggestedActions = await actions.generate(
        screenshot.id,
        parseResult.objects,
      );
      final lifecycleEvaluations = lifecycle.evaluate(parseResult.objects);
      final evaluations = lifecycleEvaluations.isEmpty
          ? const [
              LifecycleEvaluation(
                state: LifecycleState.understood,
                reason: 'Processing completed without an extracted object.',
                eventType: LifecycleEventType.understood,
              ),
            ]
          : lifecycleEvaluations;

      final lifecycleState = _selectLifecycleState(
        evaluations,
        suggestedActions.isNotEmpty,
      );
      final finishedAt = clock.now();
      final processedScreenshot = screenshot.copyWith(
        processingStatus: ScreenshotProcessingStatus.processed,
        ocrText: recognizedText.text,
        primaryType: classification.type,
        primarySubtype: classification.subtype,
        classificationConfidence: classification.confidence,
        currentLifecycleState: lifecycleState,
        lastProcessedAt: finishedAt,
      );
      final events = [
        for (final evaluation in evaluations)
          LifecycleEvent(
            id: ids.next(),
            screenshotId: screenshot.id,
            type: evaluation.eventType ?? LifecycleEventType.understood,
            timestamp: finishedAt,
            reason: evaluation.reason,
            metadata: evaluation.metadata,
          ),
      ];
      final result = ProcessingResult(
        screenshot: processedScreenshot,
        entities: entities,
        objects: parseResult.objects,
        actions: suggestedActions,
        lifecycleEvents: events,
      );
      await store.persist(result);
      return result;
    } catch (error, stackTrace) {
      await store.markFailed(screenshot, clock.now(), error);
      Error.throwWithStackTrace(
        ScreenshotProcessingException(
          'Failed to process screenshot ${screenshot.id}.',
          error,
        ),
        stackTrace,
      );
    }
  }

  static LifecycleState _selectLifecycleState(
    List<LifecycleEvaluation> evaluations,
    bool hasActions,
  ) {
    if (evaluations.isEmpty) return LifecycleState.understood;
    const rank = <LifecycleState, int>{
      LifecycleState.understood: 0,
      LifecycleState.keep: 1,
      LifecycleState.upcoming: 2,
      LifecycleState.expiring: 3,
      LifecycleState.expired: 4,
      LifecycleState.cleanupCandidate: 5,
      LifecycleState.deleted: 6,
    };
    final state = evaluations
        .map((evaluation) => evaluation.state)
        .reduce((a, b) => (rank[a] ?? 0) >= (rank[b] ?? 0) ? a : b);
    if (state == LifecycleState.understood && hasActions) {
      return LifecycleState.actionable;
    }
    return state;
  }
}
