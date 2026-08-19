import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';

void main() {
  test('normalizes OCR geometry and assigns stable ordered IDs', () {
    final value = const RecognizedText(
      fullText: '20% OFF',
      blocks: [
        RecognizedTextBlock(
          text: '20% OFF',
          boundingBox: RecognitionBounds(
            left: 100,
            top: 200,
            right: 900,
            bottom: 300,
          ),
          lines: [
            RecognizedTextLine(
              text: '20% OFF',
              boundingBox: RecognitionBounds(
                left: 100,
                top: 200,
                right: 900,
                bottom: 300,
              ),
            ),
          ],
        ),
      ],
    ).normalizedFor(width: 1000, height: 2000);

    expect(value.blocks.single.id, 'B01');
    expect(value.blocks.single.lines.single.id, 'B01L01');
    expect(value.blocks.single.boundingBox!.left, 0.1);
    expect(value.blocks.single.boundingBox!.top, 0.1);
    expect(value.blocks.single.boundingBox!.width, 0.8);
  });

  test('deterministic entities retain their supporting block IDs', () async {
    const recognized = RecognizedText(
      fullText: 'NIKE\n20% OFF',
      blocks: [
        RecognizedTextBlock(id: 'B01', text: 'NIKE', lines: []),
        RecognizedTextBlock(id: 'B02', text: '20% OFF', lines: []),
      ],
    );
    final context = ProcessingContext(
      screenshot: screenshotFixture(),
      imageBytes: Uint8List.fromList([1]),
      recognizedText: recognized,
    );
    final entities = await RegexEntityExtractor(SequenceIdGenerator())
        .extract(context);

    expect(entities.single.metadata['blockIds'], ['B02']);
  });
}
