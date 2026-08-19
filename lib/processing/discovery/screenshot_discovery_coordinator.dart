import 'dart:async';

import 'package:screenshot_inbox/core/debug/local_debug_log.dart';
import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/processing/performance/processing_metrics.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/pipeline/fast_scan_result.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_result.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_version.dart';
import 'package:screenshot_inbox/processing/pipeline/screenshot_processing_pipeline.dart';
import 'package:screenshot_inbox/processing/queue/processing_queue.dart';
import 'package:screenshot_inbox/processing/scheduling/processing_scheduler.dart';

enum DiscoveryPhase {
  idle,
  finding,
  processing,
  paused,
  complete,
  permissionDenied,
  failed,
}

final class DiscoveryState {
  const DiscoveryState({
    required this.phase,
    this.permission = PhotoPermissionState.notDetermined,
    this.discovered = 0,
    this.newScreenshots = 0,
    this.pending = 0,
    this.active = 0,
    this.processed = 0,
    this.fastScanned = 0,
    this.deepAnalyzed = 0,
    this.aiSkipped = 0,
    this.cached = 0,
    this.deferred = 0,
    this.failures = 0,
    this.message,
    this.metrics = const ProcessingSessionMetrics.empty(),
  });

  const DiscoveryState.idle() : this(phase: DiscoveryPhase.idle);

  final DiscoveryPhase phase;
  final PhotoPermissionState permission;
  final int discovered;
  final int newScreenshots;
  final int pending;
  final int active;
  final int processed;
  final int fastScanned;
  final int deepAnalyzed;
  final int aiSkipped;
  final int cached;
  final int deferred;
  final int failures;
  final String? message;
  final ProcessingSessionMetrics metrics;

  bool get isWorking =>
      phase == DiscoveryPhase.finding || phase == DiscoveryPhase.processing;
  bool get hasLimitedAccess => permission == PhotoPermissionState.limited;

  DiscoveryState copyWith({
    DiscoveryPhase? phase,
    PhotoPermissionState? permission,
    int? discovered,
    int? newScreenshots,
    int? pending,
    int? active,
    int? processed,
    int? fastScanned,
    int? deepAnalyzed,
    int? aiSkipped,
    int? cached,
    int? deferred,
    int? failures,
    String? message,
    ProcessingSessionMetrics? metrics,
  }) => DiscoveryState(
    phase: phase ?? this.phase,
    permission: permission ?? this.permission,
    discovered: discovered ?? this.discovered,
    newScreenshots: newScreenshots ?? this.newScreenshots,
    pending: pending ?? this.pending,
    active: active ?? this.active,
    processed: processed ?? this.processed,
    fastScanned: fastScanned ?? this.fastScanned,
    deepAnalyzed: deepAnalyzed ?? this.deepAnalyzed,
    aiSkipped: aiSkipped ?? this.aiSkipped,
    cached: cached ?? this.cached,
    deferred: deferred ?? this.deferred,
    failures: failures ?? this.failures,
    message: message ?? this.message,
    metrics: metrics ?? this.metrics,
  );
}

final class ScreenshotDiscoveryCoordinator {
  static const maxDeepRetryAttempts = 3;

  ScreenshotDiscoveryCoordinator({
    required this.photos,
    required this.screenshots,
    required this.pipeline,
    required this.store,
    required this.scheduler,
    required this.metrics,
    required this.clock,
    required this.ids,
    this.batchSize = 40,
  }) {
    _fastQueue = ProcessingQueue<Screenshot>(
      concurrency: scheduler.concurrency.fastScanConcurrency,
      worker: _processFast,
      priority: (item) => item.createdAt.millisecondsSinceEpoch.toDouble(),
      keyOf: (item) => item.id,
      maxAttempts: 2,
    );
    _deepQueue = ProcessingQueue<_DeepJob>(
      concurrency: scheduler.concurrency.deepAnalysisConcurrency,
      worker: _processDeep,
      priority: (item) => item.fast.priority.score,
      keyOf: (item) => item.fast.screenshot.id,
      // Deep retries are persisted and rescheduled after nextRetryAt. Retrying
      // inside this queue would bypass that durable backoff after a restart.
      maxAttempts: 1,
    );
    _fastSubscription = _fastQueue.states.listen((_) => _onQueueState());
    _deepSubscription = _deepQueue.states.listen((_) => _onQueueState());
  }

  final PhotoRepository photos;
  final ScreenshotRepository screenshots;
  final ScreenshotProcessingPipeline pipeline;
  final ProcessingStore store;
  final ProcessingScheduler scheduler;
  final ProcessingMetricsCollector metrics;
  final Clock clock;
  final IdGenerator ids;
  final int batchSize;

  late final ProcessingQueue<Screenshot> _fastQueue;
  late final ProcessingQueue<_DeepJob> _deepQueue;
  late final StreamSubscription<ProcessingQueueSnapshot> _fastSubscription;
  late final StreamSubscription<ProcessingQueueSnapshot> _deepSubscription;
  final StreamController<DiscoveryState> _states = StreamController.broadcast(
    sync: true,
  );
  var _state = const DiscoveryState.idle();
  var _generation = 0;
  var _scanning = false;
  var _scanComplete = false;
  var _includeHistorical = false;
  var _aiSkipped = 0;
  var _cached = 0;
  var _deferred = 0;
  final Set<String> _deepReservations = {};

  Stream<DiscoveryState> get states => _states.stream;
  DiscoveryState get state => _state;

  Future<void> start() async {
    if (_scanning || _state.isWorking) return;
    final generation = ++_generation;
    _scanning = true;
    _scanComplete = false;
    _set(
      const DiscoveryState(
        phase: DiscoveryPhase.finding,
        message: 'Finding screenshots…',
      ),
    );
    try {
      final permission = await photos.currentPermission();
      if (generation != _generation) return;
      if (!permission.canRead) {
        _set(
          DiscoveryState(
            phase: DiscoveryPhase.permissionDenied,
            permission: permission,
            message: 'Photo access is needed to find screenshots.',
          ),
        );
        return;
      }
      _set(_state.copyWith(permission: permission));
      final visibleAssetIds = <String>{};

      await for (final batch in photos.getScreenshotBatches(
        batchSize: batchSize,
      )) {
        if (generation != _generation) return;
        metrics.discovered(batch.length);
        final existing = await screenshots.findByAssetIds(
          batch.map((asset) => asset.id),
        );
        final records = await store.findProcessingRecords(
          existing.values.map((item) => item.id),
        );
        visibleAssetIds.addAll(batch.map((asset) => asset.id));
        var newCount = 0;
        for (final asset in batch) {
          var screenshot = existing[asset.id];
          if (screenshot == null) {
            screenshot = Screenshot(
              id: ids.next(),
              assetId: asset.id,
              createdAt: asset.createdAt,
              indexedAt: clock.now(),
              width: asset.width,
              height: asset.height,
              sizeBytes: asset.sizeBytes,
              processingStatus: ScreenshotProcessingStatus.queued,
              currentLifecycleState: LifecycleState.newItem,
              processingVersion: ProcessingVersion.current,
            );
            await screenshots.save(screenshot);
            newCount++;
          }
          await _route(screenshot, records[screenshot.id]);
        }
        _set(
          _state.copyWith(
            phase: DiscoveryPhase.processing,
            discovered: _state.discovered + batch.length,
            newScreenshots: _state.newScreenshots + newCount,
            message: _state.newScreenshots + newCount == 0
                ? 'Checking the processing cache…'
                : 'Analyzing recent screenshots…',
          ),
        );
      }
      if (permission == PhotoPermissionState.authorized &&
          visibleAssetIds.isNotEmpty) {
        final stored = await screenshots.findAll();
        for (final screenshot in stored) {
          if (!screenshot.assetId.startsWith('debug://') &&
              !visibleAssetIds.contains(screenshot.assetId) &&
              screenshot.currentLifecycleState != LifecycleState.deleted) {
            await screenshots.setLifecycleState(
              screenshot.id,
              LifecycleState.deleted,
            );
          }
        }
      }
      _scanComplete = true;
      _finishIfIdle();
    } catch (error) {
      if (generation == _generation) {
        _set(
          _state.copyWith(
            phase: DiscoveryPhase.failed,
            message: 'Screenshot discovery failed. Pull to try again.',
          ),
        );
      }
    } finally {
      if (generation == _generation) _scanning = false;
    }
  }

  Future<void> _route(Screenshot screenshot, ProcessingRecord? record) async {
    final expectedFast = pipeline.fastFingerprint(screenshot);
    final expectedDeep = pipeline.deepFingerprint(screenshot);
    if (record?.deepCacheMatches(expectedDeep) == true &&
        screenshot.processingStatus == ScreenshotProcessingStatus.processed) {
      _cached++;
      metrics.cached();
      return;
    }
    if (record?.fastCacheMatches(expectedFast) == true) {
      final fast = await store.loadFastScan(screenshot, record!);
      if (fast != null) {
        _cached++;
        metrics.cached();
        final routing = await pipeline.decideDeepAnalysis(
          fast,
          isNewOrRecent: scheduler.isRecent(screenshot.createdAt, clock.now()),
        );
        if (routing.shouldEnqueue) {
          if (_canAttemptDeep(record)) {
            await _enqueueDeep(fast, routing);
          } else {
            _deferred++;
          }
        } else if (screenshot.processingStatus !=
            ScreenshotProcessingStatus.processed) {
          await pipeline.finalizeWithoutAI(fast, routing: routing);
          _aiSkipped++;
        }
        return;
      }
    }

    final recent = scheduler.isRecent(screenshot.createdAt, clock.now());
    if (_includeHistorical || recent) {
      _fastQueue.enqueue(
        screenshot.copyWith(
          processingStatus: ScreenshotProcessingStatus.queued,
          processingVersion: ProcessingVersion.current,
        ),
      );
      return;
    }
    await _defer(screenshot, record);
  }

  Future<void> _defer(Screenshot screenshot, ProcessingRecord? existing) async {
    _deferred++;
    final record =
        existing ??
        ProcessingRecord(
          screenshotId: screenshot.id,
          assetFingerprint: pipeline.assetFingerprint(screenshot),
          fastState: FastScanState.pending,
          deepState: DeepAnalysisState.deferred,
          updatedAt: clock.now(),
        );
    await store.saveProcessingRecord(
      record.copyWith(
        deepState: DeepAnalysisState.deferred,
        updatedAt: clock.now(),
      ),
    );
  }

  Future<void> _processFast(Screenshot screenshot) async {
    final isNewOrRecent = scheduler.isRecent(screenshot.createdAt, clock.now());
    final decision = await scheduler.decide(
      recent: _includeHistorical || isNewOrRecent,
      priority: 0,
    );
    _fastQueue.setConcurrency(decision.fastConcurrency);
    if (!decision.allowFastScan) {
      await _defer(screenshot, await store.findProcessingRecord(screenshot.id));
      return;
    }
    final fast = await pipeline.fastScan(screenshot);
    final routing = await pipeline.decideDeepAnalysis(
      fast,
      isNewOrRecent: isNewOrRecent,
    );
    if (routing.shouldEnqueue) {
      await _enqueueDeep(fast, routing);
    } else {
      await pipeline.finalizeWithoutAI(fast, routing: routing);
      _aiSkipped++;
    }
  }

  Future<void> _enqueueDeep(
    FastScanResult fast,
    DeepAnalysisRoutingDecision routing,
  ) async {
    final screenshotId = fast.screenshot.id;
    if (!_deepReservations.add(screenshotId)) return;
    try {
      final decision = await scheduler.decide(
        recent:
            _includeHistorical ||
            scheduler.isRecent(fast.screenshot.createdAt, clock.now()),
        priority: fast.priority.score,
      );
      if (!decision.allowDeepAnalysis) {
        final record = await store.findProcessingRecord(screenshotId);
        if (record != null) {
          await store.saveProcessingRecord(
            record.copyWith(
              deepState: DeepAnalysisState.deferred,
              clearDeepFingerprint: true,
              updatedAt: clock.now(),
            ),
          );
        }
        _deferred++;
        _deepReservations.remove(screenshotId);
        return;
      }
      final record = await store.findProcessingRecord(screenshotId);
      if (record != null) {
        await store.saveProcessingRecord(
          record.copyWith(
            deepState: DeepAnalysisState.queued,
            clearDeepFingerprint: true,
            updatedAt: clock.now(),
          ),
        );
      }
      final enqueued = _deepQueue.enqueue(
        _DeepJob(fast, routing),
        onAccepted: () => LocalDebugLog.event(
          'processing.deep_analysis.queued',
          metadata: {
            'screenshotId': screenshotId,
            'reason': routing.reason,
            'priority': fast.priority.score,
            'classificationHint': fast.context.classification?.type.value,
          },
        ),
      );
      if (!enqueued) {
        if (record != null) await store.saveProcessingRecord(record);
        _deepReservations.remove(screenshotId);
      }
    } catch (_) {
      _deepReservations.remove(screenshotId);
      rethrow;
    }
  }

  Future<void> _processDeep(_DeepJob job) async {
    try {
      await pipeline.deepAnalyze(job.fast, routing: job.routing);
    } finally {
      _deepReservations.remove(job.fast.screenshot.id);
    }
  }

  void pause() {
    if (_scanComplete &&
        _fastQueue.snapshot.isIdle &&
        _deepQueue.snapshot.isIdle) {
      return;
    }
    _fastQueue.pause();
    _deepQueue.pause();
    _set(_state.copyWith(phase: DiscoveryPhase.paused));
  }

  void resume() {
    _fastQueue.resume();
    _deepQueue.resume();
    if (_scanComplete &&
        _fastQueue.snapshot.isIdle &&
        _deepQueue.snapshot.isIdle) {
      _finishIfIdle();
    } else {
      _set(_state.copyWith(phase: DiscoveryPhase.processing));
    }
  }

  void setAppExecutionState(AppExecutionState value) {
    scheduler.appState = value;
  }

  Future<void> analyzeRemaining({int? limit}) async {
    _includeHistorical = true;
    // A schema-v2 screenshot can be marked processed while having no v3 stage
    // record. Selecting only aggregate processing statuses would strand that
    // historical library forever, so derive remaining work from fingerprints.
    final candidates =
        (await screenshots.findAll())
            .where(
              (item) => item.currentLifecycleState != LifecycleState.deleted,
            )
            .toList(growable: false)
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final records = await store.findProcessingRecords(
      candidates.map((item) => item.id),
    );
    final unresolved = candidates.where((screenshot) {
      final record = records[screenshot.id];
      final current =
          record?.deepCacheMatches(pipeline.deepFingerprint(screenshot)) ==
              true &&
          screenshot.processingStatus == ScreenshotProcessingStatus.processed;
      final fastCurrent =
          record?.fastCacheMatches(pipeline.fastFingerprint(screenshot)) ==
          true;
      return !current &&
          (record == null || !fastCurrent || _canAttemptDeep(record));
    });
    final selected = limit == null ? unresolved : unresolved.take(limit);
    for (final screenshot in selected) {
      await _route(screenshot, records[screenshot.id]);
    }
    resume();
  }

  bool _canAttemptDeep(ProcessingRecord record) {
    if (record.retryCount >= maxDeepRetryAttempts) return false;
    final nextRetryAt = record.nextRetryAt;
    return nextRetryAt == null || !clock.now().isBefore(nextRetryAt);
  }

  Future<int> clearProcessingCache() async {
    pause();
    return store.clearProcessingCache();
  }

  Future<ProcessingCacheStats> processingStats() => store.processingStats();

  AIEligibilityMode get aiEligibilityMode => pipeline.aiEligibilityMode;
  ProcessingConcurrencyConfig get concurrency => scheduler.concurrency;
  Duration get recentWindow => scheduler.config.recentWindow;

  void setDebugTuning({
    AIEligibilityMode? aiMode,
    int? fastConcurrency,
    int? deepConcurrency,
    Duration? recentWindow,
  }) {
    if (aiMode != null) pipeline.setAIEligibilityMode(aiMode);
    final nextFast =
        fastConcurrency ?? scheduler.concurrency.fastScanConcurrency;
    final nextDeep =
        deepConcurrency ?? scheduler.concurrency.deepAnalysisConcurrency;
    scheduler.setConcurrency(fast: nextFast, deep: nextDeep);
    _fastQueue.setConcurrency(nextFast);
    _deepQueue.setConcurrency(nextDeep);
    if (recentWindow != null) scheduler.setRecentWindow(recentWindow);
  }

  Future<void> reprocessSelected(String screenshotId) async {
    final screenshot = await screenshots.findById(screenshotId);
    if (screenshot == null) return;
    await store.clearProcessingCacheFor(screenshotId);
    final queued = screenshot.copyWith(
      processingStatus: ScreenshotProcessingStatus.queued,
      processingVersion: ProcessingVersion.current,
    );
    await screenshots.save(queued);
    _fastQueue.enqueue(queued);
    resume();
  }

  Future<void> restart() async {
    _generation++;
    _scanning = false;
    _fastQueue.cancelPending();
    _deepQueue.cancelPending();
    _deepReservations.clear();
    _state = const DiscoveryState.idle();
    _includeHistorical = false;
    _aiSkipped = 0;
    _cached = 0;
    _deferred = 0;
    await start();
  }

  Future<void> dispose() async {
    _generation++;
    await _fastSubscription.cancel();
    await _deepSubscription.cancel();
    await _fastQueue.dispose();
    await _deepQueue.dispose();
    await _states.close();
  }

  void _onQueueState() {
    final fast = _fastQueue.snapshot;
    final deep = _deepQueue.snapshot;
    _set(
      _state.copyWith(
        pending: fast.pending + deep.pending,
        active: fast.active + deep.active,
        processed: fast.completed,
        fastScanned: fast.completed,
        deepAnalyzed: deep.completed,
        aiSkipped: _aiSkipped,
        cached: _cached,
        deferred: _deferred,
        failures: fast.failed + deep.failed,
        metrics: metrics.snapshot,
      ),
    );
    _finishIfIdle();
  }

  void _finishIfIdle() {
    if (_scanComplete &&
        _fastQueue.snapshot.isIdle &&
        _deepQueue.snapshot.isIdle) {
      _set(
        _state.copyWith(
          phase: DiscoveryPhase.complete,
          message: _state.failures == 0
              ? _deferred == 0
                    ? 'Screenshot scan is up to date.'
                    : 'Recent screenshots are ready. $_deferred older items are deferred.'
              : 'Scan finished with ${_state.failures} item failures.',
        ),
      );
    }
  }

  void _set(DiscoveryState value) {
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }
}

final class _DeepJob {
  const _DeepJob(this.fast, this.routing);
  final FastScanResult fast;
  final DeepAnalysisRoutingDecision routing;
}
