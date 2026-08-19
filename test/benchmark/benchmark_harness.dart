import 'dart:convert';
import 'dart:io';

final class BenchmarkCase {
  const BenchmarkCase({
    required this.id,
    required this.category,
    required this.capture,
    required this.locale,
    required this.timezone,
    required this.blocks,
    required this.expectedType,
    required this.expectedFields,
  });

  final String id;
  final String category;
  final DateTime capture;
  final String locale;
  final String timezone;
  final List<Map<String, Object?>> blocks;
  final String expectedType;
  final Map<String, Object?> expectedFields;

  factory BenchmarkCase.fromJson(Map<String, Object?> json) => BenchmarkCase(
    id: json['id']! as String,
    category: json['category']! as String,
    capture: DateTime.parse(json['capture']! as String),
    locale: json['locale']! as String,
    timezone: json['timezone']! as String,
    blocks: (json['blocks']! as List)
        .whereType<Map>()
        .map(
          (block) => block.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false),
    expectedType: json['expectedType']! as String,
    expectedFields: (json['expectedFields']! as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    ),
  );
}

final class BenchmarkPrediction {
  const BenchmarkPrediction({required this.type, required this.fields});
  final String type;
  final Map<String, Object?> fields;
}

final class BenchmarkMetrics {
  const BenchmarkMetrics({
    required this.typeCorrect,
    required this.typeTotal,
    required this.fieldCorrect,
    required this.fieldTotal,
  });

  final int typeCorrect;
  final int typeTotal;
  final Map<String, int> fieldCorrect;
  final Map<String, int> fieldTotal;

  double fieldAccuracy(String field) => (fieldTotal[field] ?? 0) == 0
      ? 0
      : (fieldCorrect[field] ?? 0) / fieldTotal[field]!;
}

Future<List<BenchmarkCase>> loadBenchmarkCorpus() async {
  final source = await File('test/fixtures/benchmark/corpus.json')
      .readAsString();
  return (jsonDecode(source) as List)
      .whereType<Map>()
      .map(
        (item) => BenchmarkCase.fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .toList(growable: false);
}

BenchmarkMetrics scoreBenchmark(
  List<BenchmarkCase> corpus,
  Map<String, BenchmarkPrediction> predictions,
) {
  var typeCorrect = 0;
  final fieldCorrect = <String, int>{};
  final fieldTotal = <String, int>{};
  for (final fixture in corpus) {
    final prediction = predictions[fixture.id];
    if (prediction?.type == fixture.expectedType) typeCorrect++;
    for (final entry in fixture.expectedFields.entries) {
      final key = '${fixture.category}.${entry.key}';
      fieldTotal.update(key, (value) => value + 1, ifAbsent: () => 1);
      if (_normalize(prediction?.fields[entry.key]) ==
          _normalize(entry.value)) {
        fieldCorrect.update(key, (value) => value + 1, ifAbsent: () => 1);
      }
    }
  }
  return BenchmarkMetrics(
    typeCorrect: typeCorrect,
    typeTotal: corpus.length,
    fieldCorrect: fieldCorrect,
    fieldTotal: fieldTotal,
  );
}

String _normalize(Object? value) =>
    value.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
