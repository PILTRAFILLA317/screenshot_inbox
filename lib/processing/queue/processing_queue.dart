import 'dart:async';

enum ProcessingQueuePhase { idle, running, paused, cancelled, disposed }

final class ProcessingQueueSnapshot {
  const ProcessingQueueSnapshot({
    required this.phase,
    required this.pending,
    required this.active,
    required this.completed,
    required this.failed,
    required this.retried,
  });

  final ProcessingQueuePhase phase;
  final int pending;
  final int active;
  final int completed;
  final int failed;
  final int retried;

  bool get isIdle => pending == 0 && active == 0;
}

final class ProcessingQueue<T> {
  ProcessingQueue({
    required this.worker,
    int concurrency = 2,
    this.priority,
    this.keyOf,
    this.maxAttempts = 1,
    this.retryDelay = const Duration(milliseconds: 250),
  }) : assert(concurrency > 0),
       assert(maxAttempts > 0),
       _concurrency = concurrency;

  final Future<void> Function(T item) worker;
  final double Function(T item)? priority;
  final String Function(T item)? keyOf;
  final int maxAttempts;
  final Duration retryDelay;
  final List<_QueuedItem<T>> _pending = [];
  final Set<String> _knownKeys = {};
  final StreamController<ProcessingQueueSnapshot> _states =
      StreamController.broadcast(sync: true);

  var _phase = ProcessingQueuePhase.idle;
  var _active = 0;
  var _completed = 0;
  var _failed = 0;
  var _retried = 0;
  var _sequence = 0;
  int _concurrency;

  int get concurrency => _concurrency;
  Stream<ProcessingQueueSnapshot> get states => _states.stream;
  ProcessingQueueSnapshot get snapshot => ProcessingQueueSnapshot(
    phase: _phase,
    pending: _pending.length,
    active: _active,
    completed: _completed,
    failed: _failed,
    retried: _retried,
  );

  bool enqueue(T item) {
    _assertOpen();
    final key = keyOf?.call(item);
    if (key != null && !_knownKeys.add(key)) return false;
    _insert(_QueuedItem(item: item, attempt: 1, sequence: _sequence++));
    if (_phase != ProcessingQueuePhase.paused) {
      _phase = ProcessingQueuePhase.running;
    }
    _emit();
    _drain();
    return true;
  }

  int enqueueAll(Iterable<T> items) {
    var added = 0;
    for (final item in items) {
      if (enqueue(item)) added++;
    }
    return added;
  }

  void setConcurrency(int value) {
    _assertOpen();
    if (value <= 0) throw ArgumentError.value(value, 'value', 'Must be > 0.');
    _concurrency = value;
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
    for (final item in _pending) {
      final key = keyOf?.call(item.value);
      if (key != null) _knownKeys.remove(key);
    }
    _pending.clear();
    _phase = _active == 0
        ? ProcessingQueuePhase.cancelled
        : ProcessingQueuePhase.running;
    _emit();
  }

  Future<void> dispose() async {
    if (_phase == ProcessingQueuePhase.disposed) return;
    _pending.clear();
    _knownKeys.clear();
    _phase = ProcessingQueuePhase.disposed;
    _emit();
    await _states.close();
  }

  void _insert(_QueuedItem<T> item) {
    _pending.add(item);
    var index = _pending.length - 1;
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (!_comesBefore(_pending[index], _pending[parent])) break;
      _swap(index, parent);
      index = parent;
    }
  }

  _QueuedItem<T> _removeFirst() {
    final first = _pending.first;
    final last = _pending.removeLast();
    if (_pending.isEmpty) return first;
    _pending[0] = last;
    var index = 0;
    while (true) {
      final left = index * 2 + 1;
      if (left >= _pending.length) break;
      final right = left + 1;
      var next = left;
      if (right < _pending.length &&
          _comesBefore(_pending[right], _pending[left])) {
        next = right;
      }
      if (!_comesBefore(_pending[next], _pending[index])) break;
      _swap(index, next);
      index = next;
    }
    return first;
  }

  bool _comesBefore(_QueuedItem<T> left, _QueuedItem<T> right) {
    final byPriority = (priority?.call(right.value) ?? 0).compareTo(
      priority?.call(left.value) ?? 0,
    );
    return byPriority != 0 ? byPriority < 0 : left.sequence < right.sequence;
  }

  void _swap(int left, int right) {
    final value = _pending[left];
    _pending[left] = _pending[right];
    _pending[right] = value;
  }

  void _drain() {
    if (_phase != ProcessingQueuePhase.running) return;
    while (_active < _concurrency && _pending.isNotEmpty) {
      final item = _removeFirst();
      _active++;
      _emit();
      unawaited(_run(item));
    }
    if (_pending.isEmpty && _active == 0) {
      _phase = ProcessingQueuePhase.idle;
      _emit();
    }
  }

  Future<void> _run(_QueuedItem<T> item) async {
    var retry = false;
    try {
      await worker(item.value);
      _completed++;
      _forget(item.value);
    } catch (_) {
      if (item.attempt < maxAttempts &&
          _phase != ProcessingQueuePhase.cancelled &&
          _phase != ProcessingQueuePhase.disposed) {
        retry = true;
        _retried++;
        await Future<void>.delayed(retryDelay * item.attempt);
        _insert(
          _QueuedItem(
            item: item.value,
            attempt: item.attempt + 1,
            sequence: _sequence++,
          ),
        );
      } else {
        _failed++;
        _forget(item.value);
      }
    } finally {
      _active--;
      if (retry && _phase == ProcessingQueuePhase.idle) {
        _phase = ProcessingQueuePhase.running;
      }
      if (_pending.isEmpty &&
          _active == 0 &&
          _phase == ProcessingQueuePhase.running) {
        _phase = ProcessingQueuePhase.idle;
      }
      _emit();
      _drain();
    }
  }

  void _forget(T value) {
    final key = keyOf?.call(value);
    if (key != null) _knownKeys.remove(key);
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

final class _QueuedItem<T> {
  const _QueuedItem({
    required this.item,
    required this.attempt,
    required this.sequence,
  });

  final T item;
  T get value => item;
  final int attempt;
  final int sequence;
}
