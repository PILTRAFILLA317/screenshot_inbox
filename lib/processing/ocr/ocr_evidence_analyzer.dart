import 'dart:math' as math;

import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';

final class OcrBlockSignal {
  const OcrBlockSignal({
    required this.blockId,
    required this.weight,
    required this.uiLikelihood,
    required this.reasons,
    this.duplicateOf,
  });

  final String blockId;
  final double weight;
  final double uiLikelihood;
  final List<String> reasons;
  final String? duplicateOf;

  bool get isLikelyUi => uiLikelihood >= OcrEvidenceThresholds.uiNoise;
  bool get isDuplicate => duplicateOf != null;

  JsonMap toJson() => {
    'blockId': blockId,
    'weight': weight,
    'uiLikelihood': uiLikelihood,
    'likelyUi': isLikelyUi,
    'duplicateOf': ?duplicateOf,
    'reasons': reasons,
  };
}

final class OcrEvidenceAnalysis {
  const OcrEvidenceAnalysis({this.signals = const []});

  final List<OcrBlockSignal> signals;

  OcrBlockSignal signalFor(String blockId) => signals.firstWhere(
    (signal) => signal.blockId == blockId,
    orElse: () => OcrBlockSignal(
      blockId: blockId,
      weight: 1,
      uiLikelihood: 0,
      reasons: const [],
    ),
  );

  List<JsonMap> get uiNoiseCandidates => [
    for (final signal in signals)
      if (signal.uiLikelihood > 0) signal.toJson(),
  ];

  List<JsonMap> get duplicateCandidates => [
    for (final signal in signals)
      if (signal.isDuplicate) signal.toJson(),
  ];

  JsonMap toJson() => {
    'uiNoiseCandidates': uiNoiseCandidates,
    'duplicateCandidates': duplicateCandidates,
    'signals': signals.map((signal) => signal.toJson()).toList(growable: false),
  };
}

abstract final class OcrEvidenceThresholds {
  static const uiNoise = 0.7;
  static const duplicateWeight = 0.42;
}

/// Produces soft evidence weights. It never removes OCR: parsers and local
/// intelligence can still inspect every block and decide that a weak signal is
/// relevant in its visual context.
final class OcrEvidenceAnalyzer {
  const OcrEvidenceAnalyzer();

  OcrEvidenceAnalysis analyze(RecognizedText text) {
    final mutable = <String, _MutableSignal>{
      for (final block in text.blocks) block.id: _MutableSignal(),
    };
    final bottomNavigation = text.blocks
        .where((block) {
          final bounds = block.boundingBox;
          return bounds != null &&
              bounds.top >= 0.8 &&
              bounds.height <= 0.09 &&
              _normalized(block.text).length <= 24;
        })
        .toList(growable: false);

    for (final block in text.blocks) {
      final signal = mutable[block.id]!;
      final bounds = block.boundingBox;
      final normalized = _normalized(block.text);
      final nearTop = bounds != null && bounds.top <= 0.18;
      final searchSemantics = _searchSemantics.hasMatch(normalized);
      final searchContainer =
          bounds != null && bounds.width >= 0.25 && bounds.height <= 0.12;
      if (nearTop && searchSemantics && searchContainer) {
        signal.uiLikelihood = 0.95;
        signal.weight = 0.12;
        signal.reasons.add(
          'Top-positioned search semantics inside a wide, shallow control.',
        );
      } else if (nearTop && searchSemantics) {
        signal.uiLikelihood = 0.72;
        signal.weight = 0.35;
        signal.reasons.add('Top-positioned text has search-control semantics.');
      } else if (nearTop && normalized.length <= 24) {
        signal.uiLikelihood = math.max(signal.uiLikelihood, 0.28);
        signal.reasons.add('Short text near the top may be app chrome.');
      }
      if (bottomNavigation.length >= 3 && bottomNavigation.contains(block)) {
        signal.uiLikelihood = math.max(signal.uiLikelihood, 0.86);
        signal.weight = math.min(signal.weight, 0.22);
        signal.reasons.add(
          'One of several small labels aligned as bottom navigation.',
        );
      }
    }

    for (var left = 0; left < text.blocks.length; left++) {
      for (var right = left + 1; right < text.blocks.length; right++) {
        final first = text.blocks[left];
        final second = text.blocks[right];
        final a = _normalized(first.text);
        final b = _normalized(second.text);
        if (a.length < 5 || b.length < 5) continue;
        final overlap = _blockSimilarity(first, second);
        final spatiallyRelated = _spatiallyRelated(first, second);
        if (overlap < (spatiallyRelated ? 0.62 : 0.76)) continue;
        final winner = _preferred(first, second);
        final fragment = identical(winner, first) ? second : first;
        final signal = mutable[fragment.id]!;
        signal.duplicateOf = winner.id;
        signal.weight = math.min(
          signal.weight,
          OcrEvidenceThresholds.duplicateWeight,
        );
        signal.reasons.add(
          'Probable partial/duplicate OCR fragment of ${winner.id} '
          '(similarity ${overlap.toStringAsFixed(2)}).',
        );
      }
    }

    return OcrEvidenceAnalysis(
      signals: [
        for (final block in text.blocks)
          OcrBlockSignal(
            blockId: block.id,
            weight: mutable[block.id]!.weight,
            uiLikelihood: mutable[block.id]!.uiLikelihood,
            reasons: List.unmodifiable(mutable[block.id]!.reasons),
            duplicateOf: mutable[block.id]!.duplicateOf,
          ),
      ],
    );
  }

  static RecognizedTextBlock _preferred(
    RecognizedTextBlock first,
    RecognizedTextBlock second,
  ) {
    double quality(RecognizedTextBlock block) {
      final normalized = _normalized(block.text);
      final addressBonus = RegExp(r'\b\d{5}\b').hasMatch(normalized) ? 18 : 0;
      final lineBonus = block.lines.length * 3;
      return (normalized.length + addressBonus + lineBonus).toDouble();
    }

    return quality(first) >= quality(second) ? first : second;
  }

  static bool _spatiallyRelated(
    RecognizedTextBlock first,
    RecognizedTextBlock second,
  ) {
    final a = first.boundingBox;
    final b = second.boundingBox;
    if (a == null || b == null) return false;
    final horizontalOverlap = math.max(
      0,
      math.min(a.right, b.right) - math.max(a.left, b.left),
    );
    final minWidth = math.min(a.width, b.width);
    final closeVertically = (a.top - b.top).abs() <= 0.12;
    return minWidth > 0 &&
        horizontalOverlap / minWidth >= 0.45 &&
        closeVertically;
  }

  static double _similarity(String left, String right) {
    if (left == right) return 1;
    if (left.contains(right) || right.contains(left)) {
      final ratio =
          math.min(left.length, right.length) /
          math.max(left.length, right.length);
      return math.min(left.length, right.length) >= 8
          ? math.max(0.78, ratio)
          : ratio;
    }
    final a = _bigrams(left);
    final b = _bigrams(right);
    if (a.isEmpty || b.isEmpty) return 0;
    final shared = a.intersection(b).length;
    return (2 * shared) / (a.length + b.length);
  }

  static double _blockSimilarity(
    RecognizedTextBlock first,
    RecognizedTextBlock second,
  ) {
    final firstValues = {
      _normalized(first.text),
      ...first.lines.map((line) => _normalized(line.text)),
    };
    final secondValues = {
      _normalized(second.text),
      ...second.lines.map((line) => _normalized(line.text)),
    };
    var best = 0.0;
    for (final left in firstValues) {
      for (final right in secondValues) {
        if (left.length < 5 || right.length < 5) continue;
        best = math.max(best, _similarity(left, right));
      }
    }
    return best;
  }

  static Set<String> _bigrams(String value) => {
    for (var index = 0; index + 1 < value.length; index++)
      value.substring(index, index + 2),
  };

  static String _normalized(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final _searchSemantics = RegExp(
    r'\b(search|find|buscar|destination|destino|query|consulta)\b',
    caseSensitive: false,
    unicode: true,
  );
}

final class _MutableSignal {
  double weight = 1;
  double uiLikelihood = 0;
  String? duplicateOf;
  final List<String> reasons = [];
}
