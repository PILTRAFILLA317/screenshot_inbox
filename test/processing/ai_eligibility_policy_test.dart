import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/ocr/ocr_evidence_analyzer.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';

void main() {
  final policy = DefaultAIEligibilityPolicy();

  test('simple QR URL skips AI', () {
    final result = policy.evaluate(
      _context(
        type: ScreenshotType.reference,
        text: 'https://example.com',
        entities: [
          _entity(EntityType.qr, 'https://example.com'),
          _entity(EntityType.url, 'https://example.com'),
        ],
      ),
      _parse(ExtractedObjectType.reference),
    );

    expect(result.needsAI, isFalse);
  });

  test('plain informational reference skips AI', () {
    final result = policy.evaluate(
      _context(
        type: ScreenshotType.reference,
        text: 'A long informational paragraph without dates or actions.',
      ),
      _parse(ExtractedObjectType.reference),
    );

    expect(result.needsAI, isFalse);
  });

  test('event with multiple dates requires AI with an explicit reason', () {
    final result = policy.evaluate(
      _context(
        type: ScreenshotType.event,
        text: 'Purchased 2026-08-20. Concert 2026-09-01.',
        entities: [
          _entity(EntityType.date, '2026-08-20'),
          _entity(EntityType.date, '2026-09-01'),
        ],
      ),
      _parse(ExtractedObjectType.event),
    );

    expect(result.needsAI, isTrue);
    expect(
      result.reasons,
      contains(AIEligibilityReason.multipleDateCandidates),
    );
  });

  test('product versus order ambiguity requires AI', () {
    final result = policy.evaluate(
      _context(
        type: ScreenshotType.product,
        text: 'Buy now · delivery tomorrow · €149',
        entities: [_entity(EntityType.money, '€149')],
      ),
      _parse(ExtractedObjectType.product),
    );

    expect(result.reasons, contains(AIEligibilityReason.commerceTypeAmbiguity));
  });

  test('place with noisy UI requires AI', () {
    final result = policy.evaluate(
      _context(
        type: ScreenshotType.place,
        text: 'Search this area Nearby Restaurant',
        analysis: const OcrEvidenceAnalysis(
          signals: [
            OcrBlockSignal(
              blockId: 'B01',
              weight: 0.1,
              uiLikelihood: 0.9,
              reasons: ['ui'],
            ),
            OcrBlockSignal(
              blockId: 'B02',
              weight: 0.2,
              uiLikelihood: 0.8,
              reasons: ['ui'],
            ),
          ],
        ),
      ),
      _parse(ExtractedObjectType.place),
    );

    expect(result.reasons, contains(AIEligibilityReason.noisyPlaceUi));
  });

  test('casual conversation skips AI but explicit future task requires it', () {
    final casual = policy.evaluate(
      _context(
        type: ScreenshotType.reference,
        text: 'That was funny, see you around.',
      ),
      _parse(ExtractedObjectType.reference),
    );
    final task = policy.evaluate(
      _context(
        type: ScreenshotType.conversationTask,
        text: "Don't forget to send the deck tomorrow.",
      ),
      _parse(ExtractedObjectType.conversationTask),
    );

    expect(casual.needsAI, isFalse);
    expect(task.needsAI, isTrue);
    expect(task.reasons, contains(AIEligibilityReason.explicitFutureTask));
  });
}

ProcessingContext _context({
  required ScreenshotType type,
  required String text,
  List<ExtractedEntity> entities = const [],
  OcrEvidenceAnalysis analysis = const OcrEvidenceAnalysis(),
}) => ProcessingContext(
  screenshot: screenshotFixture(),
  imageBytes: Uint8List(0),
  recognizedText: RecognizedText.plain(text),
  ocrAnalysis: analysis,
  entities: entities,
  classification: ClassificationResult(
    type: type,
    confidence: 0.7,
    reasons: const ['fixture'],
  ),
);

ExtractedEntity _entity(EntityType type, String value) => ExtractedEntity(
  id: '${type.value}-$value',
  screenshotId: 'screenshot-1',
  type: type,
  rawValue: value,
  normalizedValue: value,
  confidence: 1,
);

ParseResult _parse(ExtractedObjectType type) =>
    ParseResult(objects: [objectFixture(type: type)]);
