import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/processing/lifecycle/lifecycle_policy.dart';

final class TemporalLifecyclePolicy implements LifecyclePolicy {
  const TemporalLifecyclePolicy({
    this.expiringWindow = const Duration(days: 7),
  });

  final Duration expiringWindow;

  @override
  String get id => 'temporal.v1';

  @override
  int get priority => 100;

  @override
  bool supports(ExtractedObject object) =>
      _date(object.structuredData['expiresAt']) != null ||
      _date(object.structuredData['startsAt']) != null;

  @override
  LifecycleEvaluation evaluate(ExtractedObject object, DateTime now) {
    final expiresAt = _date(object.structuredData['expiresAt']);
    if (expiresAt != null) {
      if (!expiresAt.isAfter(now)) {
        return LifecycleEvaluation(
          state: LifecycleState.expired,
          reason: 'The extracted expiry date has passed.',
          eventType: LifecycleEventType.becameExpired,
          metadata: {'expiresAt': expiresAt.toIso8601String()},
        );
      }
      if (!expiresAt.isAfter(now.add(expiringWindow))) {
        return LifecycleEvaluation(
          state: LifecycleState.expiring,
          reason: 'The extracted expiry date is approaching.',
          eventType: LifecycleEventType.becameExpiring,
          metadata: {'expiresAt': expiresAt.toIso8601String()},
        );
      }
    }

    final startsAt = _date(object.structuredData['startsAt']);
    if (startsAt != null && startsAt.isAfter(now)) {
      return LifecycleEvaluation(
        state: LifecycleState.upcoming,
        reason: 'The extracted start date is in the future.',
        eventType: LifecycleEventType.understood,
        metadata: {'startsAt': startsAt.toIso8601String()},
      );
    }
    if (startsAt != null) {
      return LifecycleEvaluation(
        state: LifecycleState.cleanupCandidate,
        reason: 'The extracted event date has passed.',
        eventType: LifecycleEventType.cleanupSuggested,
        metadata: {'startsAt': startsAt.toIso8601String()},
      );
    }

    return const LifecycleEvaluation(
      state: LifecycleState.understood,
      reason: 'Temporal data is valid but has no active transition.',
      eventType: LifecycleEventType.understood,
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
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
