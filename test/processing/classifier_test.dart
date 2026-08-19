import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';
import '../support/text_corpus.dart';

void main() {
  final cases = <String, ScreenshotType>{
    eventEnglish: ScreenshotType.event,
    eventSpanish: ScreenshotType.event,
    couponEnglish: ScreenshotType.coupon,
    couponSpanish: ScreenshotType.coupon,
    conversationEnglish: ScreenshotType.conversationTask,
    conversationSpanish: ScreenshotType.conversationTask,
    orderEnglish: ScreenshotType.order,
    orderSpanish: ScreenshotType.order,
    productEnglish: ScreenshotType.product,
    productSpanish: ScreenshotType.product,
    placeEnglish: ScreenshotType.place,
    placeSpanish: ScreenshotType.place,
  };

  for (final entry in cases.entries) {
    test('classifies ${entry.value.value} fixture deterministically', () async {
      final result = await _classify(entry.key);
      expect(result.type, entry.value);
      expect(result.confidence, greaterThanOrEqualTo(0.62));
      expect(result.reasons, isNotEmpty);
    });
  }

  test(
    'uses reference fallback when useful text has weak category evidence',
    () async {
      expect((await _classify(randomReference)).type, ScreenshotType.reference);
    },
  );

  test('uses other fallback for near-empty input', () async {
    expect((await _classify(shortOther)).type, ScreenshotType.other);
  });
}

Future<ClassificationResult> _classify(String text) async {
  final context = ProcessingContext(
    screenshot: screenshotFixture(),
    imageBytes: Uint8List.fromList([1]),
    recognizedText: RecognizedText.plain(text),
  );
  final entities = await RegexEntityExtractor(SequenceIdGenerator())
      .extract(context);
  return RuleBasedScreenshotClassifier().classify(
    context.copyWith(entities: entities),
  );
}
