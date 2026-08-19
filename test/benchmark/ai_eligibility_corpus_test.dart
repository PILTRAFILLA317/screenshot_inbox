import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/entities/entity_extractor.dart';
import 'package:screenshot_inbox/processing/ocr/ocr_evidence_analyzer.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/parsers/default_screenshot_parsers.dart';
import 'package:screenshot_inbox/processing/parsers/generic_screenshot_parser.dart';
import 'package:screenshot_inbox/processing/parsers/parser_registry.dart';
import 'package:screenshot_inbox/processing/parsers/screenshot_parser.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

import '../support/fixtures.dart';
import 'benchmark_harness.dart';

void main() {
  test('selective policy measures AI demand on the local corpus', () async {
    final corpus = await loadBenchmarkCorpus();
    var eligible = 0;
    var skipped = 0;
    final eligibleIds = <String>[];
    final skippedIds = <String>[];
    for (final fixture in corpus) {
      final ids = SequenceIdGenerator();
      final clock = FixedClock(fixture.capture);
      final recognized = RecognizedText(
        fullText: fixture.blocks.map((block) => block['text']).join('\n'),
        blocks: [
          for (final block in fixture.blocks)
            RecognizedTextBlock(
              id: block['id']! as String,
              text: block['text']! as String,
              lines: const [],
              boundingBox: RecognitionBounds(
                left: (block['x']! as num).toDouble(),
                top: (block['y']! as num).toDouble(),
                right: ((block['x']! as num).toDouble() + 0.6)
                    .clamp(0, 1)
                    .toDouble(),
                bottom: ((block['y']! as num).toDouble() + 0.08)
                    .clamp(0, 1)
                    .toDouble(),
              ),
            ),
        ],
      );
      var context = ProcessingContext(
        screenshot: Screenshot(
          id: fixture.id,
          assetId: fixture.id,
          createdAt: fixture.capture,
          indexedAt: fixture.capture,
          width: 1000,
          height: 2000,
          processingStatus: ScreenshotProcessingStatus.discovered,
          currentLifecycleState: LifecycleState.newItem,
          processingVersion: 1,
        ),
        imageBytes: Uint8List(0),
        recognizedText: recognized,
        ocrAnalysis: const OcrEvidenceAnalyzer().analyze(recognized),
      );
      context = context.copyWith(
        entities: await RegexEntityExtractor(ids).extract(context),
      );
      context = context.copyWith(
        classification: await RuleBasedScreenshotClassifier().classify(context),
      );
      final parsers = ParserRegistry([
        EventParser(ids, clock),
        CouponParser(ids, clock),
        ConversationTaskParser(ids, clock),
        OrderParser(ids, clock),
        ProductParser(ids, clock),
        PlaceParser(ids, clock),
        GenericScreenshotParser(ids, clock),
      ]);
      final parser = parsers.resolve(context);
      final deterministic = parser == null
          ? const ParseResult.empty()
          : await parser.parse(context);
      final result = DefaultAIEligibilityPolicy().evaluate(
        context,
        deterministic,
      );
      if (result.needsAI) {
        eligible++;
        eligibleIds.add(fixture.id);
      } else {
        skipped++;
        skippedIds.add(fixture.id);
      }
    }

    expect(corpus, hasLength(36));
    expect(eligible, 31, reason: 'eligible=$eligibleIds skipped=$skippedIds');
    expect(skipped, 5);
  });
}
