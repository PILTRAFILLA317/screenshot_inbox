import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/processing/lifecycle/default_lifecycle_policies.dart';

import '../support/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 19, 12);

  test('event is upcoming and explicitly urgent inside 24 hours', () {
    final evaluation = const EventLifecyclePolicy().evaluate(
      objectFixture(
        type: ExtractedObjectType.event,
        structuredData: {
          'startsAt': now.add(const Duration(hours: 12)).toIso8601String(),
        },
      ),
      now,
    );

    expect(evaluation.state, LifecycleState.upcoming);
    expect(evaluation.metadata['urgent'], isTrue);
    expect(evaluation.reason, contains('24 hours'));
  });

  test('past event waits through grace period before cleanup', () {
    final policy = const EventLifecyclePolicy();
    final recent = objectFixture(
      type: ExtractedObjectType.event,
      structuredData: {
        'startsAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
    );
    final old = objectFixture(
      type: ExtractedObjectType.event,
      structuredData: {
        'startsAt': now.subtract(const Duration(days: 43)).toIso8601String(),
      },
    );

    expect(policy.evaluate(recent, now).state, LifecycleState.handled);
    expect(policy.evaluate(old, now).state, LifecycleState.cleanupCandidate);
    expect(policy.evaluate(old, now).reason, contains('43 days'));
  });

  test(
    'coupon transitions through actionable expiring expired and cleanup',
    () {
      const policy = CouponLifecyclePolicy();
      ExtractedObject coupon(Duration offset) => objectFixture(
        structuredData: {'expiresAt': now.add(offset).toIso8601String()},
      );

      expect(
        policy.evaluate(coupon(const Duration(days: 10)), now).state,
        LifecycleState.actionable,
      );
      expect(
        policy.evaluate(coupon(const Duration(hours: 48)), now).state,
        LifecycleState.expiring,
      );
      expect(
        policy.evaluate(coupon(const Duration(days: -2)), now).state,
        LifecycleState.expired,
      );
      expect(
        policy.evaluate(coupon(const Duration(days: -18)), now).state,
        LifecycleState.cleanupCandidate,
      );
    },
  );

  test('order never assumes delivery from a past expected date', () {
    final evaluation = const OrderLifecyclePolicy().evaluate(
      objectFixture(
        type: ExtractedObjectType.order,
        structuredData: const {'deliveryDate': '2026-08-18T10:00:00Z'},
      ),
      now,
    );

    expect(evaluation.state, LifecycleState.actionable);
    expect(evaluation.metadata['deliveryStatusKnown'], isFalse);
    expect(evaluation.reason, contains('review'));
  });
}
