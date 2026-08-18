import 'package:screenshot_inbox/core/utils/json_types.dart';

enum LifecycleState {
  newItem,
  understood,
  actionable,
  handled,
  keep,
  upcoming,
  expiring,
  expired,
  cleanupCandidate,
  deleted,
}

final class LifecycleEventType {
  const LifecycleEventType(this.value);

  final String value;

  static const understood = LifecycleEventType('understood');
  static const becameActionable = LifecycleEventType('becameActionable');
  static const becameExpiring = LifecycleEventType('becameExpiring');
  static const actionCompleted = LifecycleEventType('actionCompleted');
  static const becameExpired = LifecycleEventType('becameExpired');
  static const cleanupSuggested = LifecycleEventType('cleanupSuggested');
  static const kept = LifecycleEventType('kept');
  static const deleted = LifecycleEventType('deleted');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifecycleEventType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final class LifecycleEvent {
  const LifecycleEvent({
    required this.id,
    required this.screenshotId,
    required this.type,
    required this.timestamp,
    required this.reason,
    this.metadata = const {},
  });

  final String id;
  final String screenshotId;
  final LifecycleEventType type;
  final DateTime timestamp;
  final String reason;
  final JsonMap metadata;
}

final class LifecycleEvaluation {
  const LifecycleEvaluation({
    required this.state,
    required this.reason,
    this.eventType,
    this.metadata = const {},
  });

  final LifecycleState state;
  final String reason;
  final LifecycleEventType? eventType;
  final JsonMap metadata;
}
