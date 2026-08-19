import 'dart:typed_data';

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
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/image/processing_image_policy.dart';
import 'package:screenshot_inbox/processing/intelligence/intelligence_enricher.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_engine.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/ocr/ocr_evidence_analyzer.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/pipeline/fast_scan_result.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_fingerprint.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_version.dart';
import 'package:screenshot_inbox/processing/performance/processing_metrics.dart';
import 'package:screenshot_inbox/processing/priority/ai_processing_priority.dart';

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
    AIEligibilityPolicy? aiEligibility,
    AIProcessingPriorityPolicy? aiPriority,
    this.ocrEvidenceAnalyzer = const OcrEvidenceAnalyzer(),
    this.metrics,
    this.fingerprint = const ProcessingFingerprint(
      ocrVersion: ProcessingVersion.ocr,
      classifierVersion: ProcessingVersion.classifier,
      parserVersion: ProcessingVersion.parser,
      intelligenceVersion: ProcessingVersion.intelligence,
    ),
    this.intelligence,
    this.existingObjects,
  }) : aiEligibility = aiEligibility ?? DefaultAIEligibilityPolicy(),
       aiPriority = aiPriority ?? AIProcessingPriorityPolicy(clock);

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
  final AIEligibilityPolicy aiEligibility;
  final AIProcessingPriorityPolicy aiPriority;
  final OcrEvidenceAnalyzer ocrEvidenceAnalyzer;
  final ProcessingMetricsCollector? metrics;
  final ProcessingFingerprint fingerprint;
  final IntelligenceEnricher? intelligence;
  final ExtractedObjectRepository? existingObjects;

  AIEligibilityMode get aiEligibilityMode =>
      aiEligibility is DefaultAIEligibilityPolicy
      ? (aiEligibility as DefaultAIEligibilityPolicy).mode
      : AIEligibilityMode.selective;

  void setAIEligibilityMode(AIEligibilityMode value) {
    final policy = aiEligibility;
    if (policy is DefaultAIEligibilityPolicy) policy.mode = value;
  }

  String assetFingerprint(Screenshot screenshot) => [
    screenshot.assetId,
    screenshot.createdAt.toIso8601String(),
    '${screenshot.width}x${screenshot.height}',
    screenshot.sizeBytes ?? 'unknown',
  ].join('|');

  String fastFingerprint(Screenshot screenshot) =>
      fingerprint.fastFor(assetFingerprint(screenshot));

  String deepFingerprint(Screenshot screenshot) =>
      fingerprint.deepFor(fastFingerprint(screenshot));

  Future<ProcessingResult> process(Screenshot screenshot) async {
    final fast = await fastScan(screenshot);
    if (fast.eligibility.needsAI) return deepAnalyze(fast);
    return finalizeWithoutAI(fast);
  }

  Future<ProcessingResult> finalizeWithoutAI(FastScanResult fast) async {
    final result = await _finalize(
      fast: fast,
      objects: fast.deterministic.objects,
      intelligenceDiagnostics: const {
        'policy': 'eligibility',
        'invoked': false,
        'result': 'policySkipped',
        'policyDecision': 'Fast Scan found sufficient deterministic evidence.',
      },
      deepTimings: const ProcessingTimings(),
    );
    metrics?.skipped();
    return result;
  }

  Future<FastScanResult> fastScan(Screenshot screenshot) async {
    final totalWatch = Stopwatch()..start();
    final now = clock.now();
    final assetKey = assetFingerprint(screenshot);
    var record = ProcessingRecord(
      screenshotId: screenshot.id,
      assetFingerprint: assetKey,
      fastState: FastScanState.running,
      deepState: DeepAnalysisState.notEvaluated,
      updatedAt: now,
    );
    await store.markProcessing(screenshot, now);
    await store.saveProcessingRecord(record);

    try {
      final image = await photos.getProcessingImage(
        screenshot.assetId,
        purpose: ProcessingImagePurpose.ocr,
      );
      if (image == null || image.bytes.isEmpty) {
        throw const ScreenshotProcessingException(
          'Photos returned no processable image data.',
        );
      }
      var context = ProcessingContext(
        screenshot: screenshot,
        imageBytes: image.bytes,
      );

      final ocrWatch = Stopwatch()..start();
      final recognizedText = (await textRecognition.recognize(image.bytes))
          .normalizedFor(width: screenshot.width, height: screenshot.height);
      ocrWatch.stop();
      context = context.copyWith(
        recognizedText: recognizedText,
        ocrAnalysis: ocrEvidenceAnalyzer.analyze(recognizedText),
      );

      final barcodeWatch = Stopwatch()..start();
      final barcodes = await barcodeRecognition.recognize(image.bytes);
      barcodeWatch.stop();
      context = context.copyWith(barcodes: barcodes);

      final entityWatch = Stopwatch()..start();
      final entities = await entityExtractor.extract(context);
      entityWatch.stop();
      context = context.copyWith(entities: entities);

      final classificationWatch = Stopwatch()..start();
      final classification = await classifier.classify(context);
      classificationWatch.stop();
      context = context.copyWith(classification: classification);

      final parser = parsers.resolve(context);
      final parserWatch = Stopwatch()..start();
      final deterministic = parser == null
          ? const ParseResult.empty()
          : await parser.parse(context);
      parserWatch.stop();
      final eligibility = aiEligibility.evaluate(context, deterministic);
      final priority = aiPriority.evaluate(context, eligibility);
      totalWatch.stop();
      final timings = ProcessingTimings(
        values: {
          'assetLoadingMs': image.assetLoadingDuration.inMilliseconds,
          'ocrImageGenerationMs': image.generationDuration.inMilliseconds,
          'ocrMs': ocrWatch.elapsedMilliseconds,
          'barcodeMs': barcodeWatch.elapsedMilliseconds,
          'entityExtractionMs': entityWatch.elapsedMilliseconds,
          'classificationMs': classificationWatch.elapsedMilliseconds,
          'deterministicParsingMs': parserWatch.elapsedMilliseconds,
          'fastScanTotalMs': totalWatch.elapsedMilliseconds,
        },
      );
      final primary = deterministic.objects.firstOrNull;
      final provisional = screenshot.copyWith(
        processingStatus: ScreenshotProcessingStatus.processing,
        ocrText: recognizedText.text,
        primaryType: primary == null
            ? classification.type
            : ScreenshotType(primary.type.value),
        primarySubtype: primary?.subtype ?? classification.subtype,
        classificationConfidence:
            primary?.confidence ?? classification.confidence,
        currentLifecycleState: eligibility.needsAI
            ? LifecycleState.newItem
            : screenshot.currentLifecycleState,
        lastProcessedAt: clock.now(),
        processingVersion: ProcessingVersion.current,
      );
      final result = FastScanResult(
        screenshot: provisional,
        context: context.copyWith(imageBytes: Uint8List(0)),
        deterministic: deterministic,
        eligibility: eligibility,
        priority: priority,
        timings: timings,
        parserId: parser?.id,
      );
      record = record.copyWith(
        fastState: FastScanState.completed,
        deepState: eligibility.needsAI
            ? DeepAnalysisState.queued
            : DeepAnalysisState.skipped,
        updatedAt: clock.now(),
        fastFingerprint: fastFingerprint(screenshot),
        deepFingerprint: eligibility.needsAI
            ? null
            : deepFingerprint(screenshot),
        fastPayload: result.toCacheJson(),
        aiPriority: priority.score,
        aiEligibilityReasons: eligibility.reasons,
        fastTimings: timings,
      );
      final persistWatch = Stopwatch()..start();
      await store.persistFastScan(result, record);
      persistWatch.stop();
      final measured = FastScanResult(
        screenshot: result.screenshot,
        context: result.context,
        deterministic: result.deterministic,
        eligibility: result.eligibility,
        priority: result.priority,
        parserId: result.parserId,
        timings: timings.merged({
          'databaseWriteMs': persistWatch.elapsedMilliseconds,
        }),
      );
      await store.saveProcessingRecord(
        record.copyWith(fastTimings: measured.timings, updatedAt: clock.now()),
      );
      metrics?.fastCompleted(screenshot.id, measured.timings);
      return measured;
    } catch (error, stackTrace) {
      metrics?.failed();
      await store.saveProcessingRecord(
        record.copyWith(
          fastState: FastScanState.failed,
          updatedAt: clock.now(),
        ),
      );
      await _reportFailure(screenshot, error, stackTrace);
    }
  }

  Future<ProcessingResult> deepAnalyze(FastScanResult fast) async {
    final screenshot = fast.screenshot;
    final record = await store.findProcessingRecord(screenshot.id);
    if (record == null) {
      throw StateError('Deep analysis requires a persisted Fast Scan.');
    }
    await store.saveProcessingRecord(
      record.copyWith(
        deepState: DeepAnalysisState.running,
        updatedAt: clock.now(),
      ),
    );
    try {
      final totalWatch = Stopwatch()..start();
      final image = await photos.getProcessingImage(
        screenshot.assetId,
        purpose: ProcessingImagePurpose.localAI,
      );
      if (image == null || image.bytes.isEmpty) {
        throw const ScreenshotProcessingException(
          'Photos returned no image for deep analysis.',
        );
      }
      final context = fast.context.copyWith(imageBytes: image.bytes);
      final previous = existingObjects == null
          ? const <ExtractedObject>[]
          : await existingObjects!.findForScreenshot(screenshot.id);
      final intelligenceWatch = Stopwatch()..start();
      final enrichment = intelligence == null
          ? IntelligenceEnrichmentResult(
              objects: fast.deterministic.objects,
              diagnostics: const {
                'policy': 'notConfigured',
                'invoked': false,
                'result': 'providerUnavailable',
              },
            )
          : await intelligence!.enrich(
              context: context,
              deterministic: fast.deterministic,
              existingObjects: previous,
            );
      intelligenceWatch.stop();
      final resultStatus = enrichment.diagnostics['result'];
      if (resultStatus == 'timeout' || resultStatus == 'providerError') {
        throw ScreenshotProcessingException(
          'Local intelligence failed with $resultStatus.',
        );
      }
      final availability = enrichment.diagnostics['availability'];
      if (intelligence != null &&
          resultStatus == 'providerUnavailable' &&
          availability != 'unsupportedDevice' &&
          availability != 'disabled') {
        throw ScreenshotProcessingException(
          'Local intelligence is temporarily unavailable: $availability.',
        );
      }
      totalWatch.stop();
      final timings = ProcessingTimings(
        values: {
          'assetLoadingMs': image.assetLoadingDuration.inMilliseconds,
          'aiImageGenerationMs': image.generationDuration.inMilliseconds,
          'localAiMs':
              (enrichment.diagnostics['durationMs'] as num?)?.round() ??
              intelligenceWatch.elapsedMilliseconds,
          'validationMs':
              (enrichment.diagnostics['validationDurationMs'] as num?)
                  ?.round() ??
              0,
          'deepScanTotalMs': totalWatch.elapsedMilliseconds,
        },
      );
      LocalDebugLog.event(
        'processing.interpretation',
        metadata: {
          'screenshotId': screenshot.id,
          'classification': fast.context.classification?.type.value,
          'parser': fast.parserId,
          ...enrichment.diagnostics,
        },
      );
      final finalResult = await _finalize(
        fast: fast,
        context: context.copyWith(imageBytes: Uint8List(0)),
        objects: enrichment.objects,
        intelligenceDiagnostics: enrichment.diagnostics,
        deepTimings: timings,
        finalDeepState: resultStatus == 'providerUnavailable'
            ? DeepAnalysisState.skipped
            : DeepAnalysisState.completed,
      );
      metrics?.deepCompleted(screenshot.id, timings);
      return finalResult;
    } catch (error, stackTrace) {
      metrics?.failed();
      final retry = record.retryCount + 1;
      await store.saveProcessingRecord(
        record.copyWith(
          deepState: DeepAnalysisState.failed,
          retryCount: retry,
          nextRetryAt: clock.now().add(
            Duration(seconds: 2 << retry.clamp(0, 5).toInt()),
          ),
          updatedAt: clock.now(),
        ),
      );
      await _reportFailure(screenshot, error, stackTrace);
    }
  }

  Future<FastScanResult?> restoreFastScan(Screenshot screenshot) async {
    final record = await store.findProcessingRecord(screenshot.id);
    if (record == null ||
        !record.fastCacheMatches(fastFingerprint(screenshot))) {
      return null;
    }
    metrics?.cached();
    return store.loadFastScan(screenshot, record);
  }

  Future<ProcessingResult> _finalize({
    required FastScanResult fast,
    required List<ExtractedObject> objects,
    required Map<String, Object?> intelligenceDiagnostics,
    required ProcessingTimings deepTimings,
    ProcessingContext? context,
    DeepAnalysisState? finalDeepState,
  }) async {
    final actionWatch = Stopwatch()..start();
    final actionGeneration = await actions.generateWithDiagnostics(
      fast.screenshot.id,
      objects,
    );
    actionWatch.stop();
    final validationWatch = Stopwatch()..start();
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
    validationWatch.stop();
    final lifecycleState = _selectLifecycleState(
      evaluations,
      actionGeneration.actions.isNotEmpty,
    );
    final finishedAt = clock.now();
    final allTimings = fast.timings.merged({
      ...deepTimings.values,
      'actionGenerationMs': actionWatch.elapsedMilliseconds,
      'validationMs':
          deepTimings['validationMs'] + validationWatch.elapsedMilliseconds,
      'totalProcessingMs':
          fast.timings['fastScanTotalMs'] + deepTimings['deepScanTotalMs'],
    });
    final finalObjects = _withDebugDiagnostics(
      objects: objects,
      context: context ?? fast.context,
      parserId: fast.parserId,
      deterministicObjects: fast.deterministic.objects,
      intelligence: intelligenceDiagnostics,
      actions: actionGeneration.actions,
      actionDecisions: actionGeneration.decisions,
      evaluations: evaluations,
      timings: allTimings.toJson(),
    );
    final primary = finalObjects.firstOrNull;
    final classification = fast.context.classification;
    final processedScreenshot = fast.screenshot.copyWith(
      processingStatus: ScreenshotProcessingStatus.processed,
      primaryType: primary == null
          ? classification?.type
          : ScreenshotType(primary.type.value),
      primarySubtype: primary?.subtype ?? classification?.subtype,
      classificationConfidence:
          primary?.confidence ?? classification?.confidence,
      currentLifecycleState: lifecycleState,
      lastProcessedAt: finishedAt,
      processingVersion: ProcessingVersion.current,
    );
    final result = ProcessingResult(
      screenshot: processedScreenshot,
      entities: fast.context.entities,
      objects: finalObjects,
      actions: actionGeneration.actions,
      lifecycleEvents: [
        for (final evaluation in evaluations)
          LifecycleEvent(
            id: ids.next(),
            screenshotId: fast.screenshot.id,
            type: evaluation.eventType ?? LifecycleEventType.understood,
            timestamp: finishedAt,
            reason: evaluation.reason,
            metadata: evaluation.metadata,
          ),
      ],
    );
    final writeWatch = Stopwatch()..start();
    await store.persist(result);
    writeWatch.stop();
    final current = await store.findProcessingRecord(fast.screenshot.id);
    if (current != null) {
      await store.saveProcessingRecord(
        current.copyWith(
          deepState: fast.eligibility.needsAI
              ? finalDeepState ?? DeepAnalysisState.completed
              : DeepAnalysisState.skipped,
          deepFingerprint: deepFingerprint(fast.screenshot),
          deepTimings: deepTimings.merged({
            'databaseWriteMs': writeWatch.elapsedMilliseconds,
          }),
          retryCount: 0,
          clearNextRetryAt: true,
          updatedAt: clock.now(),
        ),
      );
    }
    return result;
  }

  Future<Never> _reportFailure(
    Screenshot screenshot,
    Object error,
    StackTrace stackTrace,
  ) async {
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
