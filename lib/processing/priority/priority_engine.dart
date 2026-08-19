import 'dart:math' as math;

import 'package:screenshot_inbox/domain/inbox/inbox_item.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';

abstract final class PriorityWeights {
  static const actionability = 32.0;
  static const urgent = 24.0;
  static const expiry = 22.0;
  static const confidence = 14.0;
  static const recency = 8.0;
  static const handledPenalty = 100.0;
}

final class PriorityEngine {
  const PriorityEngine();

  double score(InboxItem item, DateTime now) {
    var score = 0.0;
    if (item.needsAction) score += PriorityWeights.actionability;
    if (item.screenshot.currentLifecycleState == LifecycleState.expiring) {
      score += PriorityWeights.urgent;
    }

    final expiry = item.expiryDate;
    if (expiry != null && expiry.isAfter(now)) {
      final hours = expiry.difference(now).inMinutes / 60;
      score +=
          PriorityWeights.expiry *
          (1 - math.min(1, math.max(0, hours / (24 * 30))));
    }

    final confidence =
        item.object?.confidence ??
        item.screenshot.classificationConfidence ??
        0;
    score += confidence.clamp(0, 1) * PriorityWeights.confidence;

    final ageHours = math.max(
      0,
      now.difference(item.screenshot.createdAt).inMinutes / 60,
    );
    score += PriorityWeights.recency * (1 - math.min(1, ageHours / (24 * 30)));

    if (item.isHandled) score -= PriorityWeights.handledPenalty;
    return score;
  }

  List<InboxItem> rank(Iterable<InboxItem> items, DateTime now) {
    final ranked = items.toList(growable: false);
    ranked.sort((a, b) {
      final byScore = score(b, now).compareTo(score(a, now));
      return byScore != 0
          ? byScore
          : b.screenshot.createdAt.compareTo(a.screenshot.createdAt);
    });
    return ranked;
  }
}
