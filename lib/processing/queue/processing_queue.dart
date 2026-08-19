import 'dart:async';
import 'dart:collection';

enum ProcessingQueuePhase { idle, running, paused, cancelled, disposed }

final class ProcessingQueueSnapshot {
  const ProcessingQueueSnapshot({
    required this.phase,
    required this.pending,
    required this.active,
    required this.completed,
    required this.failed,
  });

  final ProcessingQueuePhase phase;
  final int pending;
  final int active;
  final int completed;
  final int failed;

  bool get isIdle => pending == 0 && active == 0;
}

final class ProcessingQueue<T> {
  ProcessingQueue({required this.worker, this.concurrency = 2})
    : assert(concurrency > 0);

  final Future<void> Function(T item) worker;
  final int concurrency;
  final Queue<T> _pending = Queue<T>();
  final StreamController<ProcessingQueueSnapshot> _states =
      StreamController.broadcast(sync: true);

  var _phase = ProcessingQueuePhase.idle;
  var _active = 0;
  var _completed = 0;
  var _failed = 0;

  Stream<ProcessingQueueSnapshot> get states => _states.stream;
  ProcessingQueueSnapshot get snapshot => ProcessingQueueSnapshot(
    phase: _phase,
    pending: _pending.length,
    active: _active,
    completed: _completed,
    failed: _failed,
  );

  void enqueue(T item) {
    _assertOpen();
    _pending.add(item);
    if (_phase != ProcessingQueuePhase.paused) {
      _phase = ProcessingQueuePhase.running;
    }
    _emit();
    _drain();
  }

  void enqueueAll(Iterable<T> items) {
    _assertOpen();
    _pending.addAll(items);
    if (_pending.isEmpty) return;
    if (_phase != ProcessingQueuePhase.paused) {
      _phase = ProcessingQueuePhase.running;
    }
    _emit();
    _drain();
  }

  void pause() {
    _assertOpen();
    _phase = ProcessingQueuePhase.paused;
    _emit();
  }

  void resume() {
    _assertOpen();
    _phase = _pending.isEmpty && _active == 0
        ? ProcessingQueuePhase.idle
        : ProcessingQueuePhase.running;
    _emit();
    _drain();
  }

  void cancelPending() {
    _assertOpen();
    _pending.clear();
    _phase = _active == 0
        ? ProcessingQueuePhase.cancelled
        : ProcessingQueuePhase.running;
    _emit();
  }

  Future<void> dispose() async {
    if (_phase == ProcessingQueuePhase.disposed) return;
    _pending.clear();
    _phase = ProcessingQueuePhase.disposed;
    _emit();
    await _states.close();
  }

  void _drain() {
    if (_phase != ProcessingQueuePhase.running) return;
    while (_active < concurrency && _pending.isNotEmpty) {
      final item = _pending.removeFirst();
      _active++;
      _emit();
      unawaited(_run(item));
    }
    if (_pending.isEmpty && _active == 0) {
      _phase = ProcessingQueuePhase.idle;
      _emit();
    }
  }

  Future<void> _run(T item) async {
    try {
      await worker(item);
      _completed++;
    } catch (_) {
      _failed++;
    } finally {
      _active--;
      if (_pending.isEmpty &&
          _active == 0 &&
          _phase == ProcessingQueuePhase.running) {
        _phase = ProcessingQueuePhase.idle;
      }
      _emit();
      _drain();
    }
  }

  void _emit() {
    if (!_states.isClosed) _states.add(snapshot);
  }

  void _assertOpen() {
    if (_phase == ProcessingQueuePhase.disposed) {
      throw StateError('ProcessingQueue is disposed.');
    }
  }
}
