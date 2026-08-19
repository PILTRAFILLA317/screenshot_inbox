import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/entities/temporal_parser.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/default_screenshot_parsers.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';

void main() {
  test('event date wins over purchase date and seat/order noise', () async {
    final value = await _parse(
      '''
← Ticketmaster
BAD BUNNY
Riyadh Air Metropolitano
Madrid
12 SEP 2026 · 21:00
Sector 104
Row 12
Seat 8
Order #49382
Purchased 4 JUL 2026
Home Tickets Profile
''',
      ScreenshotType.event,
      (ids) => EventParser(ids, FixedClock(DateTime.utc(2026, 8, 19))),
    );

    expect(value.title, 'BAD BUNNY');
    expect(value.structuredData['date'], '2026-09-12');
    expect(value.structuredData['time'], '21:00');
    expect(value.structuredData['venue'], 'Riyadh Air Metropolitano');
    expect(value.structuredData['city'], 'Madrid');
  });

  test('relative tomorrow is anchored to capture date, not current date', () {
    final values = const TemporalParser().dates(
      'Acuérdate de llamar mañana',
      DateTime(2026, 8, 3, 23, 30),
    );

    expect(values.single.normalized, '2026-08-04');
  });

  test('missing year rolls into next year only when date is clearly past', () {
    final values = const TemporalParser().dates(
      'Valid until 5 January',
      DateTime(2026, 12, 20),
    );

    expect(values.single.normalized, '2027-01-05');
  });

  test('coupon picks expiry near label rather than terms date', () async {
    final value = await _parse(
      '''
NIKE
20% OFF
SUMMER20
Expires 21 August 2026
Terms updated 4 July 2026
Shop now
''',
      ScreenshotType.coupon,
      (ids) => CouponParser(ids, FixedClock(DateTime.utc(2026, 8, 19))),
    );

    expect(value.structuredData['discount'], '20%');
    expect(value.structuredData['couponCode'], 'SUMMER20');
    expect(value.structuredData['expiryDate'], '2026-08-21');
  });

  test(
    'product ignores old and shipping prices when current price is first',
    () async {
      final value = await _parse(
        '''
Sony WH-1000XM6
399 EUR
Was 449 EUR
Shipping 9 EUR
Add to cart
''',
        ScreenshotType.product,
        (ids) => ProductParser(ids, FixedClock(DateTime.utc(2026, 8, 19))),
      );

      expect(value.structuredData['price'], '399 EUR');
    },
  );

  test('casual conversation does not classify as a task', () async {
    final context = await _context('''
Mario
Qué buena estuvo la película ayer
Sí, totalmente
18:42
''');
    final classification = await RuleBasedScreenshotClassifier().classify(
      context,
    );

    expect(classification.type, isNot(ScreenshotType.conversationTask));
  });
}

Future<ExtractedObject> _parse(
  String text,
  ScreenshotType type,
  ScreenshotParser Function(SequenceIdGenerator ids) parser,
) async {
  final ids = SequenceIdGenerator();
  var context = await _context(text, ids: ids);
  context = context.copyWith(
    classification: ClassificationResult(
      type: type,
      subtype: '${type.value}.deterministic',
      confidence: 0.9,
    ),
  );
  return (await parser(ids).parse(context)).objects.single;
}

Future<ProcessingContext> _context(
  String text, {
  SequenceIdGenerator? ids,
}) async {
  final generator = ids ?? SequenceIdGenerator();
  var context = ProcessingContext(
    screenshot: screenshotFixture(),
    imageBytes: Uint8List.fromList([1]),
    recognizedText: RecognizedText.plain(text),
  );
  context = context.copyWith(
    entities: await RegexEntityExtractor(generator).extract(context),
  );
  return context;
}
