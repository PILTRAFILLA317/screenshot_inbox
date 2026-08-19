import 'dart:async';

import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/photo_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';
import 'package:screenshot_inbox/processing/pipeline/screenshot_processing_pipeline.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_version.dart';
import 'package:screenshot_inbox/processing/queue/processing_queue.dart';

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
    this.failures = 0,
    this.message,
  });

  const DiscoveryState.idle() : this(phase: DiscoveryPhase.idle);

  final DiscoveryPhase phase;
  final PhotoPermissionState permission;
  final int discovered;
  final int newScreenshots;
  final int pending;
  final int active;
  final int processed;
  final int failures;
  final String? message;

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
    int? failures,
    String? message,
  }) => DiscoveryState(
    phase: phase ?? this.phase,
    permission: permission ?? this.permission,
    discovered: discovered ?? this.discovered,
    newScreenshots: newScreenshots ?? this.newScreenshots,
    pending: pending ?? this.pending,
    active: active ?? this.active,
    processed: processed ?? this.processed,
    failures: failures ?? this.failures,
    message: message ?? this.message,
  );
}

final class ScreenshotDiscoveryCoordinator {
  ScreenshotDiscoveryCoordinator({
    required this.photos,
    required this.screenshots,
    required this.pipeline,
    required this.clock,
    required this.ids,
    this.batchSize = 40,
    this.concurrency = 2,
  }) {
    _queue = ProcessingQueue<Screenshot>(
      concurrency: concurrency,
      worker: _process,
    );
    _queueSubscription = _queue.states.listen(_onQueueState);
  }

  final PhotoRepository photos;
  final ScreenshotRepository screenshots;
  final ScreenshotProcessingPipeline pipeline;
  final Clock clock;
  final IdGenerator ids;
  final int batchSize;
  final int concurrency;

  late final ProcessingQueue<Screenshot> _queue;
  late final StreamSubscription<ProcessingQueueSnapshot> _queueSubscription;
  final StreamController<DiscoveryState> _states = StreamController.broadcast(
    sync: true,
  );
  final Set<String> _queuedIds = {};
  var _state = const DiscoveryState.idle();
  var _generation = 0;
  var _scanning = false;
  var _scanComplete = false;

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

      final interrupted = await screenshots.findByProcessingStatuses({
        ScreenshotProcessingStatus.queued,
        ScreenshotProcessingStatus.processing,
        ScreenshotProcessingStatus.failed,
      });
      for (final screenshot in interrupted) {
        _enqueue(
          screenshot.copyWith(
            processingStatus: ScreenshotProcessingStatus.queued,
          ),
        );
      }

      await for (final batch in photos.getScreenshotBatches(
        batchSize: batchSize,
      )) {
        if (generation != _generation) return;
        final existing = await screenshots.findByAssetIds(
          batch.map((asset) => asset.id),
        );
        visibleAssetIds.addAll(batch.map((asset) => asset.id));
        var newCount = 0;
        for (final asset in batch) {
          final stored = existing[asset.id];
          if (stored != null) {
            if (stored.processingStatus !=
                    ScreenshotProcessingStatus.processed ||
                stored.processingVersion < ProcessingVersion.current) {
              _enqueue(
                stored.copyWith(
                  processingStatus: ScreenshotProcessingStatus.queued,
                  processingVersion: ProcessingVersion.current,
                ),
              );
            }
            continue;
          }
          final screenshot = Screenshot(
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
          _enqueue(screenshot);
          newCount++;
        }
        _set(
          _state.copyWith(
            phase: DiscoveryPhase.processing,
            discovered: _state.discovered + batch.length,
            newScreenshots: _state.newScreenshots + newCount,
            message: _state.newScreenshots + newCount == 0
                ? 'Checking for new screenshots…'
                : 'Analyzing screenshots on this device…',
          ),
        );
      }
      // An empty inventory can also mean an OEM-specific Android album name we
      // could not identify. Never mass-mark existing rows as deleted in that
      // ambiguous case.
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

  void pause() {
    if (_scanComplete && _queue.snapshot.isIdle) return;
    _queue.pause();
    _set(_state.copyWith(phase: DiscoveryPhase.paused));
  }

  void resume() {
    _queue.resume();
    if (_scanComplete && _queue.snapshot.isIdle) {
      _finishIfIdle();
    } else {
      _set(_state.copyWith(phase: DiscoveryPhase.processing));
    }
  }

  Future<void> restart() async {
    _generation++;
    _scanning = false;
    _queue.cancelPending();
    _queuedIds.clear();
    _state = const DiscoveryState.idle();
    await start();
  }

  Future<void> dispose() async {
    _generation++;
    await _queueSubscription.cancel();
    await _queue.dispose();
    await _states.close();
  }

  void _enqueue(Screenshot screenshot) {
    if (!_queuedIds.add(screenshot.id)) return;
    _queue.enqueue(screenshot);
  }

  Future<void> _process(Screenshot screenshot) async {
    try {
      await pipeline.process(screenshot);
    } finally {
      _queuedIds.remove(screenshot.id);
    }
  }

  void _onQueueState(ProcessingQueueSnapshot queue) {
    _set(
      _state.copyWith(
        pending: queue.pending,
        active: queue.active,
        processed: queue.completed,
        failures: queue.failed,
      ),
    );
    _finishIfIdle();
  }

  void _finishIfIdle() {
    if (_scanComplete && _queue.snapshot.isIdle) {
      _set(
        _state.copyWith(
          phase: DiscoveryPhase.complete,
          message: _state.failures == 0
              ? 'Screenshot scan is up to date.'
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
