import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/default_screenshot_parsers.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';
import '../support/text_corpus.dart';

void main() {
  final now = DateTime.utc(2026, 8, 19, 12);

  test('EventParser extracts date, time, venue and city', () async {
    final object = await _parse(
      eventEnglish,
      ScreenshotType.event,
      (ids) => EventParser(ids, FixedClock(now)),
    );

    expect(object.title, 'Coldplay Live');
    expect(object.structuredData['date'], '2026-08-22');
    expect(object.structuredData['time'], '21:00');
    expect(object.structuredData['venue'], 'Wembley Stadium');
    expect(object.structuredData['city'], 'London');
    expect(object.structuredData['startsAt'], isNotNull);
  });

  test('CouponParser extracts merchant, discount, code and expiry', () async {
    final object = await _parse(
      couponSpanish,
      ScreenshotType.coupon,
      (ids) => CouponParser(ids, FixedClock(now)),
    );

    expect(object.structuredData['merchant'], 'El Corte Inglés');
    expect(object.structuredData['discount'], '15%');
    expect(object.structuredData['couponCode'], 'VUELTA15');
    expect(object.structuredData['expiryDate'], '2026-08-30');
  });

  test(
    'ConversationTaskParser extracts task, person and reminder time',
    () async {
      final object = await _parse(
        conversationSpanish,
        ScreenshotType.conversationTask,
        (ids) => ConversationTaskParser(ids, FixedClock(now)),
      );

      expect(object.title, contains('llamar al taller'));
      expect(object.structuredData['person'], 'Laura');
      expect(object.structuredData['date'], '2026-08-19');
      expect(object.structuredData['time'], '09:00');
      expect(object.structuredData['remindAt'], isNotNull);
    },
  );

  test(
    'OrderParser extracts merchant, identifiers, delivery and URL',
    () async {
      final object = await _parse(
        orderEnglish,
        ScreenshotType.order,
        (ids) => OrderParser(ids, FixedClock(now)),
      );

      expect(object.structuredData['merchant'], 'ACME Store');
      expect(object.structuredData['orderNumber'], 'AB-12345');
      expect(object.structuredData['trackingNumber'], '1Z999AA10123456784');
      expect(object.structuredData['deliveryDate'], '2026-08-24');
      expect(object.structuredData['url'], contains('/track/'));
    },
  );

  test('ProductParser extracts product, price, merchant and URL', () async {
    final object = await _parse(
      productSpanish,
      ScreenshotType.product,
      (ids) => ProductParser(ids, FixedClock(now)),
    );

    expect(object.structuredData['productName'], contains('Cafetera'));
    expect(object.structuredData['price'], '599 EUR');
    expect(object.structuredData['merchant'], 'Café Market');
    expect(object.structuredData['url'], 'https://example.es/cafetera');
  });

  test(
    'PlaceParser extracts name, address and city without inventing coordinates',
    () async {
      final object = await _parse(
        placeSpanish,
        ScreenshotType.place,
        (ids) => PlaceParser(ids, FixedClock(now)),
      );

      expect(object.structuredData['name'], 'La Viña');
      expect(object.structuredData['address'], 'Calle 31 de Agosto, 3');
      expect(object.structuredData['city'], 'San Sebastián');
      expect(object.structuredData.containsKey('latitude'), isFalse);
    },
  );
}

Future<ExtractedObject> _parse(
  String text,
  ScreenshotType type,
  ScreenshotParser Function(SequenceIdGenerator ids) parser,
) async {
  final ids = SequenceIdGenerator();
  var context = ProcessingContext(
    screenshot: screenshotFixture(),
    imageBytes: Uint8List.fromList([1]),
    recognizedText: RecognizedText.plain(text),
  );
  context = context.copyWith(
    entities: await RegexEntityExtractor(ids).extract(context),
    classification: ClassificationResult(
      type: type,
      subtype: '${type.value}.deterministic',
      confidence: 0.9,
      reasons: const ['fixture signal'],
    ),
  );
  return (await parser(ids).parse(context)).objects.single;
}
