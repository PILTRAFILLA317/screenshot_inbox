import 'dart:typed_data';

import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';

final class ProcessingContext {
  const ProcessingContext({
    required this.screenshot,
    required this.imageBytes,
    this.recognizedText = const RecognizedText(fullText: ''),
    this.barcodes = const [],
    this.entities = const [],
    this.classification,
  });

  final Screenshot screenshot;
  final Uint8List imageBytes;
  final RecognizedText recognizedText;
  String get ocrText => recognizedText.fullText;
  final List<RecognizedBarcode> barcodes;
  final List<ExtractedEntity> entities;
  final ClassificationResult? classification;

  ProcessingContext copyWith({
    RecognizedText? recognizedText,
    List<RecognizedBarcode>? barcodes,
    List<ExtractedEntity>? entities,
    ClassificationResult? classification,
  }) {
    return ProcessingContext(
      screenshot: screenshot,
      imageBytes: imageBytes,
      recognizedText: recognizedText ?? this.recognizedText,
      barcodes: barcodes ?? this.barcodes,
      entities: entities ?? this.entities,
      classification: classification ?? this.classification,
    );
  }
}
