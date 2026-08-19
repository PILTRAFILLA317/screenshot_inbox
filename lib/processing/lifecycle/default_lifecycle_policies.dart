import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy.dart';

final class HandledLifecyclePolicy implements LifecyclePolicy {
  const HandledLifecyclePolicy();

  @override
  String get id => 'handled.v1';
  @override
  int get priority => 1000;
  @override
  bool supports(ExtractedObject object) => object.handled;
  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) =>
      const LifecycleEvaluation(
        state: LifecycleState.handled,
        reason: 'The suggested action was completed or dismissed.',
        eventType: LifecycleEventType.actionCompleted,
      );
}

final class EventLifecyclePolicy implements LifecyclePolicy {
  const EventLifecyclePolicy({
    this.urgentWindow = const Duration(hours: 24),
    this.cleanupGracePeriod = const Duration(days: 14),
  });

  final Duration urgentWindow;
  final Duration cleanupGracePeriod;

  @override
  String get id => 'event-lifecycle.v1';
  @override
  int get priority => 1500;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.event &&
      _importantDate(object) != null;

  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) {
    final startsAt = _importantDate(object)!;
    if (startsAt.isAfter(now)) {
      final urgent = startsAt.difference(now) <= urgentWindow;
      return LifecycleEvaluation(
        state: LifecycleState.upcoming,
        reason: urgent
            ? 'This event starts within 24 hours.'
            : 'This event is upcoming.',
        eventType: LifecycleEventType.becameActionable,
        metadata: {'startsAt': startsAt.toIso8601String(), 'urgent': urgent},
      );
    }
    final age = now.difference(startsAt);
    if (age >= cleanupGracePeriod) {
      return LifecycleEvaluation(
        state: LifecycleState.cleanupCandidate,
        reason: 'This event ended ${age.inDays} days ago.',
        eventType: LifecycleEventType.cleanupSuggested,
        metadata: {'startsAt': startsAt.toIso8601String()},
      );
    }
    return LifecycleEvaluation(
      state: LifecycleState.handled,
      reason: 'This event date has passed.',
      eventType: LifecycleEventType.understood,
      metadata: {'startsAt': startsAt.toIso8601String()},
    );
  }
}

final class CouponLifecyclePolicy implements LifecyclePolicy {
  const CouponLifecyclePolicy({
    this.expiringWindow = const Duration(hours: 72),
    this.cleanupGracePeriod = const Duration(days: 7),
  });

  final Duration expiringWindow;
  final Duration cleanupGracePeriod;

  @override
  String get id => 'coupon-lifecycle.v1';
  @override
  int get priority => 1500;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.coupon &&
      _importantDate(object) != null;

  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) {
    final expiry = _importantDate(object)!;
    if (expiry.isAfter(now)) {
      final expiring = expiry.difference(now) <= expiringWindow;
      return LifecycleEvaluation(
        state: expiring ? LifecycleState.expiring : LifecycleState.actionable,
        reason: expiring
            ? 'This coupon expires within 72 hours.'
            : 'This coupon is still valid.',
        eventType: expiring
            ? LifecycleEventType.becameExpiring
            : LifecycleEventType.becameActionable,
        metadata: {'expiresAt': expiry.toIso8601String()},
      );
    }
    final age = now.difference(expiry);
    if (age >= cleanupGracePeriod) {
      return LifecycleEvaluation(
        state: LifecycleState.cleanupCandidate,
        reason: 'This coupon expired ${age.inDays} days ago.',
        eventType: LifecycleEventType.cleanupSuggested,
        metadata: {'expiresAt': expiry.toIso8601String()},
      );
    }
    return LifecycleEvaluation(
      state: LifecycleState.expired,
      reason: age.inDays == 0
          ? 'This coupon expired today.'
          : 'This coupon expired ${age.inDays} days ago.',
      eventType: LifecycleEventType.becameExpired,
      metadata: {'expiresAt': expiry.toIso8601String()},
    );
  }
}

final class OrderLifecyclePolicy implements LifecyclePolicy {
  const OrderLifecyclePolicy();

  @override
  String get id => 'order-lifecycle.v1';
  @override
  int get priority => 400;
  @override
  bool supports(ExtractedObject object) =>
      object.type == ExtractedObjectType.order &&
      _date(object.structuredData['deliveryDate']) != null;

  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) {
    final delivery = _date(object.structuredData['deliveryDate'])!;
    if (delivery.isAfter(now)) {
      return LifecycleEvaluation(
        state: LifecycleState.upcoming,
        reason: 'The known delivery date is upcoming.',
        eventType: LifecycleEventType.becameActionable,
        metadata: {'deliveryDate': delivery.toIso8601String()},
      );
    }
    return LifecycleEvaluation(
      state: LifecycleState.actionable,
      reason: 'The expected delivery date passed; review the order status.',
      eventType: LifecycleEventType.becameActionable,
      metadata: {
        'deliveryDate': delivery.toIso8601String(),
        'deliveryStatusKnown': false,
      },
    );
  }
}

final class SavedObjectLifecyclePolicy implements LifecyclePolicy {
  const SavedObjectLifecyclePolicy({
    this.cleanupGracePeriod = const Duration(days: 7),
  });

  final Duration cleanupGracePeriod;

  @override
  String get id => 'saved-object-lifecycle.v1';
  @override
  int get priority => 1400;
  @override
  bool supports(ExtractedObject object) => object.saved;

  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) {
    final age = now.difference(object.updatedAt);
    if (age >= cleanupGracePeriod) {
      return const LifecycleEvaluation(
        state: LifecycleState.cleanupCandidate,
        reason:
            'The useful details were saved separately from this screenshot.',
        eventType: LifecycleEventType.cleanupSuggested,
      );
    }
    return const LifecycleEvaluation(
      state: LifecycleState.handled,
      reason: 'The useful details were saved.',
      eventType: LifecycleEventType.actionCompleted,
    );
  }
}

/// Backward-compatible generic temporal policy for custom object types.
final class TemporalLifecyclePolicy implements LifecyclePolicy {
  const TemporalLifecyclePolicy({
    this.expiringWindow = const Duration(days: 7),
  });

  final Duration expiringWindow;

  @override
  String get id => 'temporal.v1';
  @override
  int get priority => 50;
  @override
  bool supports(ExtractedObject object) =>
      _date(object.structuredData['expiresAt']) != null ||
      _date(object.structuredData['startsAt']) != null;

  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) {
    final expiry = _date(object.structuredData['expiresAt']);
    if (expiry != null) {
      if (!expiry.isAfter(now)) {
        return const LifecycleEvaluation(
          state: LifecycleState.expired,
          reason: 'The extracted expiry date has passed.',
          eventType: LifecycleEventType.becameExpired,
        );
      }
      if (expiry.difference(now) <= expiringWindow) {
        return const LifecycleEvaluation(
          state: LifecycleState.expiring,
          reason: 'The extracted expiry date is approaching.',
          eventType: LifecycleEventType.becameExpiring,
        );
      }
    }
    final startsAt = _date(object.structuredData['startsAt']);
    if (startsAt != null && startsAt.isAfter(now)) {
      return const LifecycleEvaluation(
        state: LifecycleState.upcoming,
        reason: 'The extracted start date is in the future.',
        eventType: LifecycleEventType.understood,
      );
    }
    if (startsAt != null) {
      return const LifecycleEvaluation(
        state: LifecycleState.cleanupCandidate,
        reason: 'The extracted event date has passed.',
        eventType: LifecycleEventType.cleanupSuggested,
      );
    }
    return const LifecycleEvaluation(
      state: LifecycleState.understood,
      reason: 'Temporal data is valid but has no active transition.',
      eventType: LifecycleEventType.understood,
    );
  }
}

final class DefaultLifecyclePolicy implements LifecyclePolicy {
  const DefaultLifecyclePolicy();

  @override
  String get id => 'default.v1';
  @override
  int get priority => -1000;
  @override
  bool supports(ExtractedObject object) => true;
  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) =>
      const LifecycleEvaluation(
        state: LifecycleState.understood,
        reason: 'The screenshot was understood and has no temporal transition.',
        eventType: LifecycleEventType.understood,
      );
}

DateTime? _importantDate(ExtractedObject object) =>
    _date(object.structuredData['importantDate']) ??
    _date(object.structuredData['expiresAt']) ??
    _date(object.structuredData['startsAt']);

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
