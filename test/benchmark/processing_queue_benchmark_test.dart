import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/processing/queue/processing_queue.dart';

void main() {
  for (final size in const [100, 500, 1500, 5000]) {
    test('priority queue drains a metadata-only library of $size', () async {
      var active = 0;
      var maximumActive = 0;
      final visited = <int>[];
      final queue = ProcessingQueue<int>(
        concurrency: 2,
        priority: (item) => item.toDouble(),
        keyOf: (item) => '$item',
        worker: (item) async {
          active++;
          if (active > maximumActive) maximumActive = active;
          visited.add(item);
          await Future<void>.value();
          active--;
        },
      );
      addTearDown(queue.dispose);
      queue.pause();
      queue.enqueueAll(Iterable<int>.generate(size));
      expect(queue.snapshot.pending, size);
      queue.resume();
      await queue.states.firstWhere(
        (state) => state.isIdle && state.completed == size,
      );

      expect(visited, hasLength(size));
      expect(visited.first, size - 1);
      expect(maximumActive, lessThanOrEqualTo(2));
      expect(queue.snapshot.failed, 0);
    });
  }

  test('restart restores 500 persisted IDs without duplicate jobs', () async {
    final persistedIds = List<int>.generate(500, (index) => index);
    final visited = <int>[];
    final restored = ProcessingQueue<int>(
      concurrency: 2,
      keyOf: (item) => '$item',
      worker: (item) async => visited.add(item),
    );
    addTearDown(restored.dispose);
    restored.pause();
    for (final id in persistedIds) {
      expect(restored.enqueue(id), isTrue);
      expect(restored.enqueue(id), isFalse);
    }
    restored.resume();
    await restored.states.firstWhere(
      (state) => state.isIdle && state.completed == persistedIds.length,
    );

    expect(visited.toSet(), persistedIds.toSet());
    expect(restored.snapshot.failed, 0);
  });
}
