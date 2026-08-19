import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';
import '../support/text_corpus.dart';

void main() {
  late RegexEntityExtractor extractor;

  setUp(() => extractor = RegexEntityExtractor(SequenceIdGenerator()));

  test(
    'extracts English coupon entities with normalized date and code',
    () async {
      final entities = await extractor.extract(_context(couponEnglish));

      expect(_value(entities, EntityType.percentage), '20%');
      expect(_value(entities, EntityType.couponCode), 'RUN20');
      expect(_value(entities, EntityType.date), '2026-08-22');
    },
  );

  test('extracts Spanish conversation relative date and time', () async {
    final entities = await extractor.extract(_context(conversationSpanish));

    expect(_value(entities, EntityType.date), '2026-08-19');
    expect(_value(entities, EntityType.time), '09:00');
  });

  test('extracts order and tracking codes without confusing them', () async {
    final entities = await extractor.extract(_context(orderEnglish));

    expect(_value(entities, EntityType.orderCode), 'AB-12345');
    expect(_value(entities, EntityType.trackingCode), '1Z999AA10123456784');
    expect(_value(entities, EntityType.url), contains('/track/'));
  });

  test('extracts urls emails phones money and percentages', () async {
    const text = '''
Contact help@example.com or +34 612 345 678
Now €29.95 instead of 40 EUR — save 25%
www.example.es/deal
''';
    final entities = await extractor.extract(_context(text));

    expect(_value(entities, EntityType.email), 'help@example.com');
    expect(_value(entities, EntityType.phone), contains('612'));
    expect(
      entities.where((item) => item.type == EntityType.money),
      hasLength(2),
    );
    expect(_value(entities, EntityType.percentage), '25%');
    expect(_value(entities, EntityType.url), 'https://www.example.es/deal');
  });

  test('normalizes barcode payloads without plugin types', () async {
    final context = ProcessingContext(
      screenshot: screenshotFixture(),
      imageBytes: Uint8List.fromList([1]),
      recognizedText: const RecognizedText.plain('Scan to continue'),
      barcodes: const [
        RecognizedBarcode(
          rawValue: 'https://tickets.example/event',
          format: 'qrCode',
          valueType: 'url',
          payload: {'url': 'https://tickets.example/event'},
        ),
      ],
    );
    final entities = await extractor.extract(context);

    expect(_value(entities, EntityType.qr), 'https://tickets.example/event');
    expect(_value(entities, EntityType.url), 'https://tickets.example/event');
    expect(
      entities
          .firstWhere((item) => item.type == EntityType.qr)
          .metadata['format'],
      'qrCode',
    );
  });
}

ProcessingContext _context(String text) => ProcessingContext(
  screenshot: screenshotFixture(),
  imageBytes: Uint8List.fromList([1]),
  recognizedText: RecognizedText.plain(text),
);

String? _value(List<ExtractedEntity> entities, EntityType type) => entities
    .where((entity) => entity.type == type)
    .firstOrNull
    ?.normalizedValue;
