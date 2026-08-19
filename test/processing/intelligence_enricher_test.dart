import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';
import 'package:screenshot_inbox/infrastructure/intelligence/fake_intelligence_provider.dart';
import 'package:screenshot_inbox/processing/intelligence/intelligence_enricher.dart';
import 'package:screenshot_inbox/processing/intelligence/interpretation_validator.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';

void main() {
  late SequenceIdGenerator ids;
  late ProcessingContext context;
  late ExtractedObject deterministic;

  setUp(() {
    ids = SequenceIdGenerator();
    context = ProcessingContext(
      screenshot: screenshotFixture(),
      imageBytes: Uint8List.fromList([1]),
      recognizedText: const RecognizedText(
        fullText: 'Ticketmaster\nBAD BUNNY\n12 SEP 2026 · 21:00\nMadrid',
        blocks: [
          RecognizedTextBlock(id: 'B01', text: 'Ticketmaster', lines: []),
          RecognizedTextBlock(id: 'B02', text: 'BAD BUNNY', lines: []),
          RecognizedTextBlock(
            id: 'B03',
            text: '12 SEP 2026 · 21:00',
            lines: [],
          ),
          RecognizedTextBlock(id: 'B04', text: 'Madrid', lines: []),
        ],
      ),
    );
    deterministic = objectFixture(
      type: ExtractedObjectType.event,
      structuredData: const {
        'date': '2026-07-04',
        'time': '21:00',
        'startsAt': '2026-07-04T21:00:00',
      },
    ).copyWith(title: 'Ticketmaster');
  });

  test(
    'available provider resolves a conflicting event date with evidence',
    () async {
      final fake = FakeIntelligenceProvider(
        result: _result([
          const IntelligenceField(
            name: 'title',
            value: 'Bad Bunny',
            evidence: ['B02'],
          ),
          const IntelligenceField(
            name: 'date',
            value: '2026-09-12',
            evidence: ['B03'],
          ),
          const IntelligenceField(
            name: 'time',
            value: '21:00',
            evidence: ['B03'],
          ),
        ]),
      );
      final value = await _enricher(fake, ids).enrich(
        context: context,
        deterministic: ParseResult(objects: [deterministic]),
      );

      expect(value.objects.single.title, 'Bad Bunny');
      expect(value.objects.single.structuredData['date'], '2026-09-12');
      expect(
        value.objects.single.structuredData['startsAt'],
        '2026-09-12T21:00:00',
      );
      expect(
        fake.requests.single.screenshotCapturedAt,
        DateTime.utc(2026, 8, 18, 12),
      );
      expect(
        fake.requests.single.currentTime,
        isNot(fake.requests.single.screenshotCapturedAt),
      );
    },
  );

  test(
    'unavailable provider returns the deterministic object without error',
    () async {
      final fake = FakeIntelligenceProvider(
        state: const IntelligenceAvailability(
          state: IntelligenceAvailabilityState.unsupportedDevice,
          provider: 'fake-local',
        ),
      );
      final value = await _enricher(fake, ids).enrich(
        context: context,
        deterministic: ParseResult(objects: [deterministic]),
      );

      expect(value.objects.single.title, 'Ticketmaster');
      expect(fake.requests, isEmpty);
      expect(value.diagnostics['skipped'], isTrue);
    },
  );

  test(
    'an explicit empty interpretation removes actionable behavior',
    () async {
      final fake = FakeIntelligenceProvider(
        result: const IntelligenceResult(
          provider: 'fake-local',
          interpretations: [],
          duration: Duration(milliseconds: 10),
        ),
      );
      final value = await _enricher(fake, ids).enrich(
        context: context,
        deterministic: ParseResult(objects: [deterministic]),
      );

      expect(value.objects.single.type, ExtractedObjectType.reference);
      expect(value.objects.single.subtype, 'reference.local-ai-no-action');
    },
  );

  test('malformed values and false evidence are rejected', () async {
    final fake = FakeIntelligenceProvider(
      result: _result([
        const IntelligenceField(
          name: 'date',
          value: 'not-a-date',
          evidence: ['B03'],
        ),
        const IntelligenceField(
          name: 'city',
          value: 'Bilbao',
          evidence: ['B04'],
        ),
        const IntelligenceField(
          name: 'venue',
          value: 'Invented Arena',
          evidence: ['B99'],
        ),
      ]),
    );
    final value = await _enricher(fake, ids).enrich(
      context: context,
      deterministic: ParseResult(objects: [deterministic]),
    );

    expect(value.objects.single.structuredData['date'], '2026-07-04');
    expect(value.objects.single.structuredData.containsKey('city'), isFalse);
    expect(value.objects.single.structuredData.containsKey('venue'), isFalse);
  });

  test('timeout falls back and keeps user-confirmed fields', () async {
    final old = deterministic.copyWith(
      title: 'My confirmed title',
      structuredData: {
        ...deterministic.structuredData,
        '_userConfirmedFields': const ['title', 'importantDate'],
        'importantDate': '2026-10-01T19:00:00',
        'startsAt': '2026-10-01T19:00:00',
      },
    );
    final fake = FakeIntelligenceProvider(error: TimeoutException('slow'));
    final value = await _enricher(fake, ids).enrich(
      context: context,
      deterministic: ParseResult(objects: [deterministic]),
      existingObjects: [old],
    );

    expect(value.objects.single.title, 'My confirmed title');
    expect(
      value.objects.single.structuredData['startsAt'],
      '2026-10-01T19:00:00',
    );
    expect(value.diagnostics['reason'], contains('timed out'));
  });
}

IntelligenceEnricher _enricher(
  IntelligenceProvider provider,
  SequenceIdGenerator ids,
) => IntelligenceEnricher(
  provider: provider,
  validator: const InterpretationValidator(),
  policy: IntelligenceUsagePolicy.alwaysForSupportedTypes,
  clock: FixedClock(DateTime.utc(2026, 8, 19, 12)),
  ids: ids,
  locale: () => 'es_ES',
  timezone: () => 'Europe/Madrid',
);

IntelligenceResult _result(List<IntelligenceField> fields) =>
    IntelligenceResult(
      provider: 'fake-local',
      providerVersion: 'test',
      duration: const Duration(milliseconds: 40),
      interpretations: [
        IntelligenceInterpretation(
          type: 'event',
          subtype: 'concert',
          fields: fields,
        ),
      ],
    );
