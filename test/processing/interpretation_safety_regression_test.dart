import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/intelligence/intelligence_provider.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/infrastructure/intelligence/fake_intelligence_provider.dart';
import 'package:screenshot_inbox/processing/actions/action_evidence_gate.dart';
import 'package:screenshot_inbox/processing/actions/default_action_policies.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/intelligence/intelligence_enricher.dart';
import 'package:screenshot_inbox/processing/intelligence/interpretation_validator.dart';
import 'package:screenshot_inbox/processing/ocr/ocr_evidence_analyzer.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/default_screenshot_parsers.dart';
import 'package:screenshot_inbox/processing/parsers/generic_screenshot_parser.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 19, 12);

  test(
    'saved map address rejects search UI and keeps complete address',
    () async {
      final recognized = _mapRecognizedText();
      final analysis = const OcrEvidenceAnalyzer().analyze(recognized);
      final context = ProcessingContext(
        screenshot: screenshotFixture(),
        imageBytes: Uint8List.fromList([1, 2, 3]),
        recognizedText: recognized,
        ocrAnalysis: analysis,
        classification: const ClassificationResult(
          type: ScreenshotType.place,
          subtype: 'place.deterministic',
          confidence: 0.9,
        ),
      );

      final object = (await PlaceParser(
        SequenceIdGenerator(),
        FixedClock(now),
      ).parse(context)).objects.single;
      final actions = await const PlaceActionPolicy().propose(object);

      expect(analysis.signalFor('B02').isLikelyUi, isTrue);
      expect(analysis.signalFor('B03').duplicateOf, 'B09');
      expect(analysis.signalFor('B04').duplicateOf, 'B09');
      expect(object.subtype, 'saved_address');
      expect(object.title, 'Casa');
      expect(object.structuredData['name'], 'Casa');
      expect(
        object.structuredData['address'],
        'Independentzia Kalea, 48940, Ondiz, Bizkaia, España',
      );
      expect(object.structuredData['locality'], 'Ondiz');
      expect(object.structuredData['region'], 'Bizkaia');
      expect(object.structuredData['country'], 'España');
      expect(object.title, isNot(contains('Buscar destino')));
      expect(
        object.structuredData['address'],
        isNot(contains('Buscar destino')),
      );
      final mapsAction = actions.singleWhere(
        (action) => action.type == SuggestedActionType.maps,
      );
      expect(
        mapsAction.payload['query'],
        'Independentzia Kalea, 48940, Ondiz, Bizkaia, España',
      );
      final decision = const ActionEvidenceGate().diagnosticsFor(object).single;
      expect(decision['accepted'], isTrue);
      expect(decision['reason'], 'validated address');
      expect(decision['evidence'], ['B09']);
    },
  );

  test('validated local AI place output cannot promote search UI', () async {
    final recognized = _mapRecognizedText();
    final context = ProcessingContext(
      screenshot: screenshotFixture(),
      imageBytes: Uint8List.fromList([1, 2, 3]),
      recognizedText: recognized,
      ocrAnalysis: const OcrEvidenceAnalyzer().analyze(recognized),
      classification: const ClassificationResult(
        type: ScreenshotType.place,
        subtype: 'place.deterministic',
        confidence: 0.9,
      ),
    );
    final ids = SequenceIdGenerator();
    final deterministic = (await PlaceParser(
      ids,
      FixedClock(now),
    ).parse(context)).objects.single;
    final fake = FakeIntelligenceProvider(
      result: const IntelligenceResult(
        provider: 'geminiNano',
        imageInput: true,
        ocrInput: true,
        duration: Duration(milliseconds: 30),
        interpretations: [
          IntelligenceInterpretation(
            type: 'place',
            subtype: 'saved_address',
            fields: [
              IntelligenceField(name: 'name', value: 'Casa', evidence: ['B08']),
              IntelligenceField(
                name: 'address',
                value: 'Independentzia Kalea, 48940, Ondiz, Bizkaia, España',
                evidence: ['B09'],
              ),
              IntelligenceField(
                name: 'locality',
                value: 'Ondiz',
                evidence: ['B09'],
              ),
              IntelligenceField(
                name: 'region',
                value: 'Bizkaia',
                evidence: ['B09'],
              ),
              IntelligenceField(
                name: 'country',
                value: 'España',
                evidence: ['B09'],
              ),
              IntelligenceField(
                name: 'city',
                value: 'Buscar destino',
                evidence: ['B02'],
              ),
            ],
          ),
        ],
      ),
    );
    final result =
        await IntelligenceEnricher(
          provider: fake,
          validator: const InterpretationValidator(),
          policy: IntelligenceUsagePolicy.alwaysForSupportedTypes,
          clock: FixedClock(now),
          ids: ids,
          locale: () => 'es_ES',
          timezone: () => 'Europe/Madrid',
        ).enrich(
          context: context,
          deterministic: ParseResult(objects: [deterministic]),
        );

    final object = result.objects.single;
    expect(object.title, 'Casa');
    expect(object.structuredData['city'], isNull);
    expect(
      object.structuredData['address'],
      'Independentzia Kalea, 48940, Ondiz, Bizkaia, España',
    );
    final validation = result.diagnostics['validation'] as List<Object?>;
    expect(validation.single.toString(), contains('city'));
    expect(validation.single.toString(), contains('rejectedFields'));
  });

  test('product price and delivery copy do not classify as an order', () async {
    final ids = SequenceIdGenerator();
    var context = ProcessingContext(
      screenshot: screenshotFixture(),
      imageBytes: Uint8List.fromList([1]),
      recognizedText: const RecognizedText.plain(
        'Auriculares Pro\n€129\nComprar ahora\nEntrega mañana',
      ),
    );
    context = context.copyWith(
      entities: await RegexEntityExtractor(ids).extract(context),
    );

    final classification = await RuleBasedScreenshotClassifier().classify(
      context,
    );

    expect(classification.type, ScreenshotType.product);
    expect(classification.type, isNot(ScreenshotType.order));
  });

  test('random alphanumeric token cannot create tracking actions', () async {
    final ids = SequenceIdGenerator();
    final clock = FixedClock(now);
    var context = ProcessingContext(
      screenshot: screenshotFixture(),
      imageBytes: Uint8List.fromList([1]),
      recognizedText: const RecognizedText(
        fullText: 'ABCD12345678',
        blocks: [
          RecognizedTextBlock(id: 'B01', text: 'ABCD12345678', lines: []),
        ],
      ),
    );
    context = context.copyWith(
      entities: await RegexEntityExtractor(ids).extract(context),
      classification: const ClassificationResult(
        type: ScreenshotType.reference,
        confidence: 0.4,
      ),
    );
    final object = (await GenericScreenshotParser(ids, clock).parse(context))
        .objects
        .single;
    final actions = await const OrderActionPolicy().propose(
      object.copyWith(type: ExtractedObjectType.order),
    );

    expect(object.structuredData.containsKey('trackingNumber'), isFalse);
    expect(actions, isEmpty);
  });

  test(
    'generic parser stores only safe entities and no semantic actions',
    () async {
      final ids = SequenceIdGenerator();
      var context = ProcessingContext(
        screenshot: screenshotFixture(),
        imageBytes: Uint8List.fromList([1]),
        recognizedText: const RecognizedText.plain(
          '12 September 2026\nZXCV1234\nSome screenshot text',
        ),
        classification: const ClassificationResult(
          type: ScreenshotType.reference,
          confidence: 0.4,
        ),
      );
      context = context.copyWith(
        entities: await RegexEntityExtractor(ids).extract(context),
      );

      final object = (await GenericScreenshotParser(
        ids,
        FixedClock(now),
      ).parse(context)).objects.single;

      expect(object.type, ExtractedObjectType.reference);
      expect(object.title, 'Reference');
      expect(object.structuredData.containsKey('date'), isFalse);
      expect(object.structuredData.containsKey('trackingNumber'), isFalse);
      expect(await const OrderActionPolicy().propose(object), isEmpty);
      expect(await const CouponActionPolicy().propose(object), isEmpty);
      expect(await const PlaceActionPolicy().propose(object), isEmpty);
    },
  );

  test(
    'high-impact action gates fail closed when required fields are absent',
    () async {
      final order = await const OrderActionPolicy().propose(
        objectFixture(type: ExtractedObjectType.order),
      );
      final coupon = await const CouponActionPolicy().propose(
        objectFixture(type: ExtractedObjectType.coupon),
      );
      final event = await const EventActionPolicy().propose(
        objectFixture(
          type: ExtractedObjectType.event,
          structuredData: const {'startsAt': '2030-08-22T21:00:00Z'},
        ),
      );
      final place = await const PlaceActionPolicy().propose(
        objectFixture(
          type: ExtractedObjectType.place,
          structuredData: const {'mapsQuery': 'Buscar destino'},
        ),
      );

      expect(order, isEmpty);
      final trackingDecision = const ActionEvidenceGate()
          .diagnosticsFor(objectFixture(type: ExtractedObjectType.order))
          .first;
      expect(trackingDecision['accepted'], isFalse);
      expect(trackingDecision['reason'], 'trackingNumber == null');
      expect(
        coupon.where((item) => item.type == SuggestedActionType.copy),
        isEmpty,
      );
      expect(
        event.where(
          (item) =>
              item.type == SuggestedActionType.calendar &&
              item.payload['label'] == 'Add to Calendar',
        ),
        isEmpty,
      );
      expect(event.single.payload['label'], 'Review event');
      expect(
        place.where((item) => item.type == SuggestedActionType.maps),
        isEmpty,
      );
    },
  );

  test(
    'always policy invokes provider for reference and uses validated output',
    () async {
      final recognized = const RecognizedText(
        fullText: 'Auriculares Pro\n€129\nComprar ahora',
        blocks: [
          RecognizedTextBlock(id: 'B01', text: 'Auriculares Pro', lines: []),
          RecognizedTextBlock(id: 'B02', text: '€129', lines: []),
          RecognizedTextBlock(id: 'B03', text: 'Comprar ahora', lines: []),
        ],
      );
      final context = ProcessingContext(
        screenshot: screenshotFixture(),
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        recognizedText: recognized,
        ocrAnalysis: const OcrEvidenceAnalyzer().analyze(recognized),
        classification: const ClassificationResult(
          type: ScreenshotType.reference,
          subtype: 'reference.unclassified',
          confidence: 0.4,
        ),
      );
      final deterministic = (await GenericScreenshotParser(
        SequenceIdGenerator(),
        FixedClock(now),
      ).parse(context)).objects.single;
      final fake = FakeIntelligenceProvider(
        result: const IntelligenceResult(
          provider: 'geminiNano',
          providerVersion: 'test',
          imageInput: true,
          ocrInput: true,
          inputImageWidth: 590,
          inputImageHeight: 1280,
          duration: Duration(milliseconds: 40),
          interpretations: [
            IntelligenceInterpretation(
              type: 'product',
              subtype: 'retail_product',
              fields: [
                IntelligenceField(
                  name: 'productName',
                  value: 'Auriculares Pro',
                  evidence: ['B01'],
                ),
                IntelligenceField(
                  name: 'price',
                  value: '€129',
                  evidence: ['B02'],
                ),
              ],
            ),
          ],
        ),
      );
      final enricher = IntelligenceEnricher(
        provider: fake,
        validator: const InterpretationValidator(),
        policy: IntelligenceUsagePolicy.alwaysForSupportedTypes,
        clock: FixedClock(now),
        ids: SequenceIdGenerator(),
        locale: () => 'es_ES',
        timezone: () => 'Europe/Madrid',
      );

      final result = await enricher.enrich(
        context: context,
        deterministic: ParseResult(objects: [deterministic]),
      );

      expect(fake.requests, hasLength(1));
      expect(fake.requests.single.imageBytes, isNotEmpty);
      expect(fake.requests.single.blocks, hasLength(3));
      expect(result.diagnostics['provider'], 'geminiNano');
      expect(result.diagnostics['availability'], 'available');
      expect(result.diagnostics['invoked'], isTrue);
      expect(result.diagnostics['imageInput'], isTrue);
      expect(result.diagnostics['ocrInput'], isTrue);
      expect(result.diagnostics['result'], 'success');
      expect(result.objects.single.type, ExtractedObjectType.product);
      expect(result.objects.single.title, 'Auriculares Pro');
      expect(result.objects.single.structuredData['price'], '€129');
      expect(
        result.objects.single.structuredData['_intelligence'],
        isA<Map>().having(
          (value) => value['provider'],
          'provider',
          'geminiNano',
        ),
      );
    },
  );
}

RecognizedText _mapRecognizedText() => const RecognizedText(
  fullText: '''
Q Buscar destino
DIRECCIÓN GUARDADA
Casa
Independentzia Kalea, 48940
Ondiz, Bizkaia, España
Ir a casa con Google Maps
''',
  blocks: [
    RecognizedTextBlock(
      id: 'B02',
      text: 'Q Buscar destino',
      lines: [],
      boundingBox: RecognitionBounds(
        left: 0.0609,
        top: 0.0705,
        right: 0.3781,
        bottom: 0.087,
      ),
    ),
    RecognizedTextBlock(id: 'B03', text: 'Jndependentzia Kalea', lines: []),
    RecognizedTextBlock(id: 'B04', text: 'ia Kalea', lines: []),
    RecognizedTextBlock(id: 'B07', text: 'DIRECCIÓN GUARDADA', lines: []),
    RecognizedTextBlock(id: 'B08', text: 'Casa', lines: []),
    RecognizedTextBlock(
      id: 'B09',
      text: 'Independentzia Kalea, 48940\nOndiz, Bizkaia, España',
      lines: [
        RecognizedTextLine(
          id: 'B09L01',
          text: 'Independentzia Kalea, 48940',
          confidence: 0.96,
        ),
        RecognizedTextLine(
          id: 'B09L02',
          text: 'Ondiz, Bizkaia, España',
          confidence: 0.95,
        ),
      ],
    ),
    RecognizedTextBlock(
      id: 'B10',
      text: 'Ir a casa con Google Maps',
      lines: [],
    ),
  ],
);
