import 'dart:typed_data';

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
    return RecognizedText(result.text);
  }

  @override
  Future<void> close() => _recognizer.close();
}
