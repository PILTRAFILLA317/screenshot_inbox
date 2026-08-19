import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/processing/queue/processing_queue.dart';

void main() {
  test('limits concurrency and completes every independent item', () async {
    final gate = Completer<void>();
    var active = 0;
    var maximumActive = 0;
    final queue = ProcessingQueue<int>(
      concurrency: 2,
      worker: (item) async {
        active++;
        if (active > maximumActive) maximumActive = active;
        await gate.future;
        active--;
      },
    );
    addTearDown(queue.dispose);

    queue.enqueueAll([1, 2, 3, 4, 5]);
    await pumpEventQueue();
    expect(queue.snapshot.active, 2);
    expect(queue.snapshot.pending, 3);
    expect(maximumActive, 2);

    final finished = queue.states.firstWhere(
      (state) => state.isIdle && state.completed == 5,
    );
    gate.complete();
    await finished;

    expect(queue.snapshot.completed, 5);
    expect(queue.snapshot.failed, 0);
  });

  test('one failure does not stop later queued items', () async {
    final visited = <int>[];
    final queue = ProcessingQueue<int>(
      concurrency: 1,
      worker: (item) async {
        visited.add(item);
        if (item == 2) throw StateError('fixture failure');
      },
    );
    addTearDown(queue.dispose);
    final finished = queue.states.firstWhere(
      (state) => state.isIdle && state.completed == 2 && state.failed == 1,
    );

    queue.enqueueAll([1, 2, 3]);
    await finished;

    expect(visited, [1, 2, 3]);
  });

  test('pause blocks new work and resume continues', () async {
    final visited = <int>[];
    final queue = ProcessingQueue<int>(
      concurrency: 1,
      worker: (item) async => visited.add(item),
    );
    addTearDown(queue.dispose);

    queue.pause();
    queue.enqueueAll([1, 2]);
    await pumpEventQueue();
    expect(visited, isEmpty);
    queue.resume();
    await queue.states.firstWhere(
      (state) => state.isIdle && state.completed == 2,
    );
    expect(visited, [1, 2]);
  });

  test('higher priority work runs first', () async {
    final visited = <int>[];
    final queue = ProcessingQueue<int>(
      concurrency: 1,
      priority: (item) => item.toDouble(),
      worker: (item) async => visited.add(item),
    );
    addTearDown(queue.dispose);
    queue.pause();
    queue.enqueueAll([1, 3, 2]);
    queue.resume();
    await queue.states.firstWhere(
      (state) => state.isIdle && state.completed == 3,
    );

    expect(visited, [3, 2, 1]);
  });

  test('preserves FIFO order when priorities tie', () async {
    final visited = <int>[];
    final queue = ProcessingQueue<int>(
      concurrency: 1,
      priority: (_) => 1,
      worker: (item) async => visited.add(item),
    );
    addTearDown(queue.dispose);
    queue.pause();
    queue.enqueueAll([7, 3, 9, 1]);
    queue.resume();
    await queue.states.firstWhere(
      (state) => state.isIdle && state.completed == 4,
    );

    expect(visited, [7, 3, 9, 1]);
  });

  test('retries with a bound and does not duplicate keyed jobs', () async {
    var attempts = 0;
    final queue = ProcessingQueue<int>(
      concurrency: 1,
      keyOf: (item) => '$item',
      maxAttempts: 2,
      retryDelay: Duration.zero,
      worker: (item) async {
        attempts++;
        if (attempts == 1) throw StateError('transient');
      },
    );
    addTearDown(queue.dispose);

    expect(queue.enqueue(7), isTrue);
    expect(queue.enqueue(7), isFalse);
    await queue.states.firstWhere(
      (state) => state.isIdle && state.completed == 1,
    );

    expect(attempts, 2);
    expect(queue.snapshot.retried, 1);
  });
}
