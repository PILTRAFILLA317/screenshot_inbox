import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;
import 'package:screenshot_inbox/infrastructure/mlkit/mlkit_input_image.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';

final class MlKitTextRecognitionService implements TextRecognitionService {
  MlKitTextRecognitionService({mlkit.TextRecognizer? recognizer})
    : _recognizer = recognizer ?? mlkit.TextRecognizer();

  final mlkit.TextRecognizer _recognizer;

  @override
  Future<RecognizedText> recognize(Uint8List imageBytes) async {
    final result = await withTemporaryMlKitInputImage(
      imageBytes,
      _recognizer.processImage,
    );
    return RecognizedText(
      fullText: result.text,
      blocks: [
        for (
          var blockIndex = 0;
          blockIndex < result.blocks.length;
          blockIndex++
        )
          RecognizedTextBlock(
            id: 'B${(blockIndex + 1).toString().padLeft(2, '0')}',
            text: result.blocks[blockIndex].text,
            boundingBox: _bounds(result.blocks[blockIndex].boundingBox),
            languages: List.unmodifiable(
              result.blocks[blockIndex].recognizedLanguages,
            ),
            lines: [
              for (
                var lineIndex = 0;
                lineIndex < result.blocks[blockIndex].lines.length;
                lineIndex++
              )
                RecognizedTextLine(
                  id:
                      'B${(blockIndex + 1).toString().padLeft(2, '0')}'
                      'L${(lineIndex + 1).toString().padLeft(2, '0')}',
                  text: result.blocks[blockIndex].lines[lineIndex].text,
                  boundingBox: _bounds(
                    result.blocks[blockIndex].lines[lineIndex].boundingBox,
                  ),
                  confidence:
                      result.blocks[blockIndex].lines[lineIndex].confidence,
                  languages: List.unmodifiable(
                    result
                        .blocks[blockIndex]
                        .lines[lineIndex]
                        .recognizedLanguages,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Future<void> close() => _recognizer.close();

  static RecognitionBounds _bounds(Rect rect) => RecognitionBounds(
    left: rect.left,
    top: rect.top,
    right: rect.right,
    bottom: rect.bottom,
  );
}
