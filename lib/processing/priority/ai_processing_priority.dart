import 'dart:math' as math;

import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/domain/extraction/entity.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_type.dart';
import 'package:screenshot_inbox/processing/eligibility/ai_eligibility_policy.dart';
import 'package:screenshot_inbox/processing/pipeline/processing_context.dart';

final class AIProcessingPriority {
  const AIProcessingPriority({required this.score, required this.reasons});

  final double score;
  final List<String> reasons;
}

abstract final class AIProcessingPriorityWeights {
  static const recent = 32.0;
  static const actionable = 28.0;
  static const expiry = 34.0;
  static const nearDate = 38.0;
  static const ambiguity = 18.0;
  static const task = 28.0;
  static const event = 26.0;
  static const coupon = 24.0;
  static const place = 16.0;
  static const commerce = 14.0;
  static const agePenaltyPerMonth = 2.5;
}

final class AIProcessingPriorityPolicy {
  const AIProcessingPriorityPolicy(this.clock);

  final Clock clock;

  AIProcessingPriority evaluate(
    ProcessingContext context,
    AIEligibility eligibility,
  ) {
    final now = clock.now();
    final age = now.difference(context.screenshot.createdAt).abs();
    final reasons = <String>[];
    var score = 0.0;

    if (age <= const Duration(days: 30)) {
      final recency =
          AIProcessingPriorityWeights.recent *
          (1 - age.inHours / const Duration(days: 30).inHours).clamp(0, 1);
      score += recency;
      reasons.add('recent');
    } else {
      score -= math.min(
        24,
        age.inDays / 30 * AIProcessingPriorityWeights.agePenaltyPerMonth,
      );
    }

    final type = context.classification?.type;
    if (_actionable.contains(type?.value)) {
      score += AIProcessingPriorityWeights.actionable;
      reasons.add('actionable');
    }
    final typeWeight = switch (type) {
      ScreenshotType.event => AIProcessingPriorityWeights.event,
      ScreenshotType.coupon => AIProcessingPriorityWeights.coupon,
      ScreenshotType.conversationTask => AIProcessingPriorityWeights.task,
      ScreenshotType.place => AIProcessingPriorityWeights.place,
      ScreenshotType.product ||
      ScreenshotType.order => AIProcessingPriorityWeights.commerce,
      _ => 0.0,
    };
    score += typeWeight;

    if (eligibility.reasons.contains(
          AIEligibilityReason.ambiguousClassification,
        ) ||
        eligibility.reasons.contains(
          AIEligibilityReason.commerceTypeAmbiguity,
        )) {
      score += AIProcessingPriorityWeights.ambiguity;
      reasons.add('ambiguous');
    }

    final dates = context.entities
        .where((item) => item.type == EntityType.date)
        .map((item) => DateTime.tryParse(item.normalizedValue))
        .whereType<DateTime>();
    for (final date in dates) {
      final distance = date.difference(now).inHours;
      if (distance >= 0 && distance <= 72) {
        score += AIProcessingPriorityWeights.nearDate;
        reasons.add('nearDate');
        break;
      }
    }
    if (type == ScreenshotType.coupon &&
        context.ocrText.toLowerCase().contains(RegExp(r'expir|caduc|vence'))) {
      score += AIProcessingPriorityWeights.expiry;
      reasons.add('expirySignal');
    }

    return AIProcessingPriority(
      score: score,
      reasons: List.unmodifiable(reasons),
    );
  }

  static const _actionable = {
    'event',
    'coupon',
    'place',
    'product',
    'order',
    'conversationTask',
  };
}
