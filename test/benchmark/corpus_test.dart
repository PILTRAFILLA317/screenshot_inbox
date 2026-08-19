import 'package:flutter_test/flutter_test.dart';

import 'benchmark_harness.dart';

void main() {
  test(
    'benchmark corpus contains noisy bilingual cases and negatives',
    () async {
      final corpus = await loadBenchmarkCorpus();

      expect(corpus.length, greaterThanOrEqualTo(30));
      expect(corpus.map((item) => item.id).toSet().length, corpus.length);
      expect(
        corpus.map((item) => item.locale),
        containsAll(['es_ES', 'en_GB']),
      );
      expect(corpus.where((item) => item.category == 'noAction').length, 5);
      expect(
        corpus.map((item) => item.category).toSet(),
        containsAll([
          'event',
          'coupon',
          'product',
          'place',
          'conversationTask',
          'order',
          'noAction',
        ]),
      );
      for (final fixture in corpus) {
        expect(fixture.blocks, isNotEmpty, reason: fixture.id);
        for (final block in fixture.blocks) {
          expect(block['id'], isA<String>(), reason: fixture.id);
          expect(block['x'] as num, inInclusiveRange(0, 1), reason: fixture.id);
          expect(block['y'] as num, inInclusiveRange(0, 1), reason: fixture.id);
        }
      }
    },
  );

  test(
    'benchmark reports field accuracy without inventing missing predictions',
    () async {
      final corpus = (await loadBenchmarkCorpus()).take(2).toList();
      final first = corpus.first;
      final metrics = scoreBenchmark(corpus, {
        first.id: BenchmarkPrediction(
          type: first.expectedType,
          fields: first.expectedFields,
        ),
      });

      expect(metrics.typeCorrect, 1);
      expect(metrics.typeTotal, 2);
      expect(metrics.fieldAccuracy('event.title'), 0.5);
    },
  );
}
