import 'dart:typed_data';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;
import 'package:screenshot_inbox/infrastructure/mlkit/mlkit_input_image.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';

final class MlKitBarcodeRecognitionService
    implements BarcodeRecognitionService {
  MlKitBarcodeRecognitionService({mlkit.BarcodeScanner? scanner})
    : _scanner = scanner ?? mlkit.BarcodeScanner();

  final mlkit.BarcodeScanner _scanner;

  @override
  Future<List<RecognizedBarcode>> recognize(Uint8List imageBytes) async {
    final barcodes = await withTemporaryMlKitInputImage(
      imageBytes,
      _scanner.processImage,
    );
    return [
      for (final barcode in barcodes)
        if (barcode.rawValue case final String value)
          RecognizedBarcode(rawValue: value, format: barcode.format.name),
    ];
  }

  @override
  Future<void> close() => _scanner.close();
}
