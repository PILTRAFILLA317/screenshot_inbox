import 'dart:typed_data';

final class RecognizedText {
  const RecognizedText(this.text);

  final String text;
}

final class RecognizedBarcode {
  const RecognizedBarcode({required this.rawValue, required this.format});

  final String rawValue;
  final String format;
}

abstract interface class TextRecognitionService {
  Future<RecognizedText> recognize(Uint8List imageBytes);

  Future<void> close();
}

abstract interface class BarcodeRecognitionService {
  Future<List<RecognizedBarcode>> recognize(Uint8List imageBytes);

  Future<void> close();
}
