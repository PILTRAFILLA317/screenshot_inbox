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
          RecognizedBarcode(
            rawValue: value,
            displayValue: barcode.displayValue,
            format: barcode.format.name,
            valueType: barcode.type.name,
            boundingBox: RecognitionBounds(
              left: barcode.boundingBox.left,
              top: barcode.boundingBox.top,
              right: barcode.boundingBox.right,
              bottom: barcode.boundingBox.bottom,
            ),
            payload: _payload(barcode),
          ),
    ];
  }

  @override
  Future<void> close() => _scanner.close();

  static Map<String, Object?> _payload(mlkit.Barcode barcode) {
    final value = barcode.value;
    return switch (value) {
      mlkit.BarcodeUrl(:final url, :final title) => {
        'url': ?url,
        'title': ?title,
      },
      mlkit.BarcodeEmail(:final address, :final subject, :final body) => {
        'email': ?address,
        'subject': ?subject,
        'body': ?body,
      },
      mlkit.BarcodePhone(:final number) => {'phone': ?number},
      mlkit.BarcodeSMS(:final phoneNumber, :final message) => {
        'phone': ?phoneNumber,
        'message': ?message,
      },
      mlkit.BarcodeGeoPoint(:final latitude, :final longitude) => {
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
      mlkit.BarcodeWifi(:final ssid, :final encryptionType) => {
        'ssid': ?ssid,
        'encryptionType': ?encryptionType,
      },
      _ => const <String, Object?>{},
    };
  }
}
