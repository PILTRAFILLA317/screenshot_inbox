import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/classification/classification.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/ocr/recognition_services.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';
import 'package:screenshot_inbox/processing/priority/ai_processing_priority.dart';

import '../support/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 19, 12);
  final policy = AIProcessingPriorityPolicy(FixedClock(now));

  test('recent event outranks old reference', () {
    final recent = policy.evaluate(
      _context(
        type: ScreenshotType.event,
        capturedAt: now.subtract(const Duration(days: 1)),
      ),
      const AIEligibility(
        needsAI: true,
        reasons: [AIEligibilityReason.actionableType],
      ),
    );
    final old = policy.evaluate(
      _context(
        type: ScreenshotType.reference,
        capturedAt: now.subtract(const Duration(days: 900)),
      ),
      const AIEligibility(needsAI: false),
    );

    expect(recent.score, greaterThan(old.score));
  });

  test('coupon with near expiry outranks generic product', () {
    final coupon = policy.evaluate(
      _context(
        type: ScreenshotType.coupon,
        capturedAt: now.subtract(const Duration(days: 2)),
        text: 'Coupon expires tomorrow',
        entities: [_date(now.add(const Duration(days: 1)))],
      ),
      const AIEligibility(
        needsAI: true,
        reasons: [AIEligibilityReason.actionableType],
      ),
    );
    final product = policy.evaluate(
      _context(
        type: ScreenshotType.product,
        capturedAt: now.subtract(const Duration(days: 2)),
      ),
      const AIEligibility(
        needsAI: true,
        reasons: [AIEligibilityReason.actionableType],
      ),
    );

    expect(coupon.score, greaterThan(product.score));
  });

  test('ambiguous actionable screenshot outranks old passive screenshot', () {
    final ambiguous = policy.evaluate(
      _context(
        type: ScreenshotType.order,
        capturedAt: now.subtract(const Duration(days: 4)),
      ),
      const AIEligibility(
        needsAI: true,
        reasons: [AIEligibilityReason.commerceTypeAmbiguity],
      ),
    );
    final passive = policy.evaluate(
      _context(
        type: ScreenshotType.reference,
        capturedAt: now.subtract(const Duration(days: 500)),
      ),
      const AIEligibility(needsAI: false),
    );

    expect(ambiguous.score, greaterThan(passive.score));
  });
}

ProcessingContext _context({
  required ScreenshotType type,
  required DateTime capturedAt,
  String text = 'fixture',
  List<ExtractedEntity> entities = const [],
}) => ProcessingContext(
  screenshot: Screenshot(
    id: 'screenshot-${capturedAt.microsecondsSinceEpoch}',
    assetId: 'asset-${capturedAt.microsecondsSinceEpoch}',
    createdAt: capturedAt,
    indexedAt: capturedAt,
    width: 1080,
    height: 2400,
    processingStatus: ScreenshotProcessingStatus.discovered,
    currentLifecycleState: LifecycleState.newItem,
    processingVersion: 1,
  ),
  imageBytes: Uint8List(0),
  recognizedText: RecognizedText.plain(text),
  entities: entities,
  classification: ClassificationResult(type: type, confidence: 0.7),
);

ExtractedEntity _date(DateTime value) => ExtractedEntity(
  id: 'date',
  screenshotId: 'fixture',
  type: EntityType.date,
  rawValue: value.toIso8601String(),
  normalizedValue: value.toIso8601String(),
  confidence: 1,
);
