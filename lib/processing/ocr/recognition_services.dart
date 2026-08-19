import 'dart:typed_data';

import 'package:screenshot_inbox/core/utils/json_types.dart';

final class RecognizedText {
  const RecognizedText({required this.fullText, this.blocks = const []});

  const RecognizedText.plain(String text) : this(fullText: text);

  final String fullText;
  final List<RecognizedTextBlock> blocks;

  /// Compatibility alias for pipeline clients that only need the full text.
  String get text => fullText;

  RecognizedText normalizedFor({required int width, required int height}) {
    if (width <= 0 || height <= 0) return this;
    return RecognizedText(
      fullText: fullText,
      blocks: [
        for (var blockIndex = 0; blockIndex < blocks.length; blockIndex++)
          blocks[blockIndex].normalizedFor(
            id: 'B${(blockIndex + 1).toString().padLeft(2, '0')}',
            width: width,
            height: height,
          ),
      ],
    );
  }
}

final class RecognitionBounds {
  const RecognitionBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  RecognitionBounds normalizedFor({required int width, required int height}) =>
      RecognitionBounds(
        left: (left / width).clamp(0, 1).toDouble(),
        top: (top / height).clamp(0, 1).toDouble(),
        right: (right / width).clamp(0, 1).toDouble(),
        bottom: (bottom / height).clamp(0, 1).toDouble(),
      );

  Map<String, double> toJson() => {
    'x': left,
    'y': top,
    'width': width,
    'height': height,
  };
}

final class RecognizedTextBlock {
  const RecognizedTextBlock({
    this.id = '',
    required this.text,
    required this.lines,
    this.boundingBox,
    this.languages = const [],
  });

  final String id;
  final String text;
  final List<RecognizedTextLine> lines;
  final RecognitionBounds? boundingBox;
  final List<String> languages;

  RecognizedTextBlock normalizedFor({
    required String id,
    required int width,
    required int height,
  }) => RecognizedTextBlock(
    id: id,
    text: text,
    boundingBox: boundingBox?.normalizedFor(width: width, height: height),
    languages: languages,
    lines: [
      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++)
        lines[lineIndex].normalizedFor(
          id: '${id}L${(lineIndex + 1).toString().padLeft(2, '0')}',
          width: width,
          height: height,
        ),
    ],
  );
}

final class RecognizedTextLine {
  const RecognizedTextLine({
    this.id = '',
    required this.text,
    this.boundingBox,
    this.confidence,
    this.languages = const [],
  });

  final String id;
  final String text;
  final RecognitionBounds? boundingBox;
  final double? confidence;
  final List<String> languages;

  RecognizedTextLine normalizedFor({
    required String id,
    required int width,
    required int height,
  }) => RecognizedTextLine(
    id: id,
    text: text,
    boundingBox: boundingBox?.normalizedFor(width: width, height: height),
    confidence: confidence,
    languages: languages,
  );
}

final class RecognizedBarcode {
  const RecognizedBarcode({
    required this.rawValue,
    required this.format,
    this.displayValue,
    this.valueType = 'unknown',
    this.boundingBox,
    this.payload = const {},
  });

  final String rawValue;
  final String? displayValue;
  final String format;
  final String valueType;
  final RecognitionBounds? boundingBox;
  final JsonMap payload;
}

abstract interface class TextRecognitionService {
  Future<RecognizedText> recognize(Uint8List imageBytes);

  Future<void> close();
}

abstract interface class BarcodeRecognitionService {
  Future<List<RecognizedBarcode>> recognize(Uint8List imageBytes);

  Future<void> close();
}
