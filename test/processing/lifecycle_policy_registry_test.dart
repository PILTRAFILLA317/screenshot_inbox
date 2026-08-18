import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/processing/lifecycle/default_lifecycle_policies.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy_registry.dart';

import '../support/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 18, 12);
  final registry = LifecyclePolicyRegistry(const [
    TemporalLifecyclePolicy(),
    DefaultLifecyclePolicy(),
  ]);

  test('evaluates an approaching expiry deterministically', () {
    final object = objectFixture(
      structuredData: {
        'expiresAt': now.add(const Duration(days: 2)).toIso8601String(),
      },
    );

    final evaluation = registry.evaluate(object, now);

    expect(evaluation.state, LifecycleState.expiring);
    expect(evaluation.eventType, LifecycleEventType.becameExpiring);
  });

  test('evaluates a past event as a cleanup candidate', () {
    final object = objectFixture(
      structuredData: {
        'startsAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
      },
    );

    expect(
      registry.evaluate(object, now).state,
      LifecycleState.cleanupCandidate,
    );
  });

  test('falls back to understood for non-temporal objects', () {
    expect(
      registry.evaluate(objectFixture(), now).state,
      LifecycleState.understood,
    );
  });
}
