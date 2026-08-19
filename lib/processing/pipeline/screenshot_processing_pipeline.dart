import 'package:screenshot_inbox/core/errors/app_exception.dart';
import 'package:screenshot_inbox/core/debug/local_debug_log.dart';
import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/extraction/extraction_repositories.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/actions/action_engine.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/intelligence/intelligence_enricher.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/ocr/ocr_evidence_analyzer.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_version.dart';

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
    this.ocrEvidenceAnalyzer = const OcrEvidenceAnalyzer(),
    this.intelligence,
    this.existingObjects,
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
  final OcrEvidenceAnalyzer ocrEvidenceAnalyzer;
  final IntelligenceEnricher? intelligence;
  final ExtractedObjectRepository? existingObjects;

  Future<ProcessingResult> process(Screenshot screenshot) async {
    final totalWatch = Stopwatch()..start();
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
      final ocrWatch = Stopwatch()..start();
      final recognizedText = (await textRecognition.recognize(imageBytes))
          .normalizedFor(width: screenshot.width, height: screenshot.height);
      ocrWatch.stop();
      context = context.copyWith(
        recognizedText: recognizedText,
        ocrAnalysis: ocrEvidenceAnalyzer.analyze(recognizedText),
      );
      final barcodes = await barcodeRecognition.recognize(imageBytes);
      context = context.copyWith(barcodes: barcodes);
      final deterministicWatch = Stopwatch()..start();
      final entities = await entityExtractor.extract(context);
      context = context.copyWith(entities: entities);
      final classification = await classifier.classify(context);
      context = context.copyWith(classification: classification);
      final parser = parsers.resolve(context);
      final parseResult = parser == null
          ? const ParseResult.empty()
          : await parser.parse(context);
      deterministicWatch.stop();
      final intelligenceWatch = Stopwatch()..start();
      final previous = existingObjects == null
          ? const <ExtractedObject>[]
          : await existingObjects!.findForScreenshot(screenshot.id);
      final enrichment = intelligence == null
          ? IntelligenceEnrichmentResult(
              objects: parseResult.objects,
              diagnostics: const {
                'policy': 'notConfigured',
                'provider': null,
                'availability': null,
                'invoked': false,
                'imageInput': false,
                'ocrInput': false,
                'durationMs': 0,
                'result': 'policySkipped',
                'reason': 'policySkipped',
                'policyDecision': 'No intelligence stage configured.',
              },
            )
          : await intelligence!.enrich(
              context: context,
              deterministic: parseResult,
              existingObjects: previous,
            );
      LocalDebugLog.event(
        'processing.interpretation',
        metadata: {
          'screenshotId': screenshot.id,
          'classification': classification.type.value,
          'parser': parser?.id,
          ...enrichment.diagnostics,
        },
      );
      intelligenceWatch.stop();
      final validationWatch = Stopwatch()..start();
      final objects = enrichment.objects;
      validationWatch.stop();
      final actionGeneration = await actions.generateWithDiagnostics(
        screenshot.id,
        objects,
      );
      final suggestedActions = actionGeneration.actions;
      final lifecycleEvaluations = lifecycle.evaluate(objects);
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
      totalWatch.stop();
      final finalObjects = _withDebugDiagnostics(
        objects: objects,
        context: context,
        parserId: parser?.id,
        deterministicObjects: parseResult.objects,
        intelligence: enrichment.diagnostics,
        actions: suggestedActions,
        actionDecisions: actionGeneration.decisions,
        evaluations: evaluations,
        timings: {
          'ocrMs': ocrWatch.elapsedMilliseconds,
          'deterministicMs': deterministicWatch.elapsedMilliseconds,
          'intelligenceMs': intelligenceWatch.elapsedMilliseconds,
          'validationMs': validationWatch.elapsedMilliseconds,
          'totalMs': totalWatch.elapsedMilliseconds,
        },
      );
      final primaryObject = finalObjects.firstOrNull;
      final processedScreenshot = screenshot.copyWith(
        processingStatus: ScreenshotProcessingStatus.processed,
        ocrText: recognizedText.text,
        primaryType: primaryObject == null
            ? classification.type
            : ScreenshotType(primaryObject.type.value),
        primarySubtype: primaryObject?.subtype ?? classification.subtype,
        classificationConfidence:
            primaryObject?.confidence ?? classification.confidence,
        currentLifecycleState: lifecycleState,
        lastProcessedAt: finishedAt,
        processingVersion: ProcessingVersion.current,
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
        objects: finalObjects,
        actions: suggestedActions,
        lifecycleEvents: events,
      );
      await store.persist(result);
      return result;
    } catch (error, stackTrace) {
      LocalDebugLog.event(
        'processing.failed',
        metadata: {'screenshotId': screenshot.id},
        error: error,
        stackTrace: stackTrace,
      );
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

  static List<ExtractedObject> _withDebugDiagnostics({
    required List<ExtractedObject> objects,
    required ProcessingContext context,
    required String? parserId,
    required List<ExtractedObject> deterministicObjects,
    required Map<String, Object?> intelligence,
    required List<dynamic> actions,
    required List<Map<String, Object?>> actionDecisions,
    required List<LifecycleEvaluation> evaluations,
    required Map<String, Object?> timings,
  }) {
    const release = bool.fromEnvironment('dart.vm.product');
    if (release) return objects;
    final debug = <String, Object?>{
      'ocrBlocks': [
        for (final block in context.recognizedText.blocks)
          {
            'id': block.id,
            'text': block.text,
            'bounds': block.boundingBox?.toJson(),
            'lines': [
              for (final line in block.lines)
                {
                  'id': line.id,
                  'text': line.text,
                  'bounds': line.boundingBox?.toJson(),
                  'confidence': line.confidence,
                },
            ],
          },
      ],
      'deterministicEntities': [
        for (final entity in context.entities)
          {
            'id': entity.id,
            'type': entity.type.value,
            'rawValue': entity.rawValue,
            'normalizedValue': entity.normalizedValue,
            'confidence': entity.confidence,
            'metadata': entity.metadata,
          },
      ],
      'ocrEvidence': context.ocrAnalysis.toJson(),
      'classification': {
        'type': context.classification?.type.value,
        'subtype': context.classification?.subtype,
        'confidence': context.classification?.confidence,
        'reasons': context.classification?.reasons,
      },
      'deterministicParser': {
        'id': parserId,
        'objects': [
          for (final object in deterministicObjects)
            {
              'type': object.type.value,
              'subtype': object.subtype,
              'title': object.title,
              'fields': object.structuredData,
            },
        ],
      },
      'intelligencePolicy': {
        'policy': intelligence['policy'],
        'decision': intelligence['policyDecision'],
      },
      'providerExecution': {
        'provider': intelligence['provider'],
        'availability': intelligence['availability'],
        'availabilityDetail': intelligence['availabilityDetail'],
        'invoked': intelligence['invoked'],
        'imageInput': intelligence['imageInput'],
        'ocrInput': intelligence['ocrInput'],
        'durationMs': intelligence['durationMs'],
        'result': intelligence['result'],
        'reason': intelligence['reason'],
      },
      'localIntelligence': intelligence,
      'aiStructuredOutput': intelligence['rawStructuredResult'],
      'validationResult': intelligence['validation'],
      'actions': [
        for (final action in actions)
          {
            'type': action.type.value,
            'confidence': action.confidence,
            'payload': action.payload,
          },
      ],
      'actionDecisions': actionDecisions,
      'rejectedActions': actionDecisions
          .where((decision) => decision['accepted'] == false)
          .toList(growable: false),
      'lifecycle': [
        for (final evaluation in evaluations)
          {
            'state': evaluation.state.name,
            'reason': evaluation.reason,
            'metadata': evaluation.metadata,
          },
      ],
      'timings': timings,
    };
    return [
      for (final object in objects)
        object.copyWith(
          structuredData: {
            ...object.structuredData,
            '_debug': {
              ...debug,
              'finalFields': {
                for (final entry in object.structuredData.entries)
                  if (!entry.key.startsWith('_')) entry.key: entry.value,
              },
              'fieldProvenance': object.structuredData['_fieldMetadata'],
              'finalObject': {
                'type': object.type.value,
                'subtype': object.subtype,
                'title': object.title,
                'subtitle': object.subtitle,
                'confidence': object.confidence,
                'fields': object.structuredData,
              },
            },
          },
        ),
    ];
  }

  static LifecycleState _selectLifecycleState(
    List<LifecycleEvaluation> evaluations,
    bool hasActions,
  ) {
    if (evaluations.isEmpty) return LifecycleState.understood;
    const rank = <LifecycleState, int>{
      LifecycleState.newItem: 0,
      LifecycleState.understood: 0,
      LifecycleState.keep: 1,
      LifecycleState.handled: 2,
      LifecycleState.actionable: 3,
      LifecycleState.upcoming: 4,
      LifecycleState.expiring: 5,
      LifecycleState.expired: 6,
      LifecycleState.cleanupCandidate: 7,
      LifecycleState.deleted: 8,
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
