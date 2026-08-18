import 'package:screenshot_inbox/core/utils/json_types.dart';

final class SuggestedActionType {
  const SuggestedActionType(this.value);

  final String value;

  static const calendar = SuggestedActionType('calendar');
  static const reminder = SuggestedActionType('reminder');
  static const maps = SuggestedActionType('maps');
  static const openUrl = SuggestedActionType('openUrl');
  static const copy = SuggestedActionType('copy');
  static const track = SuggestedActionType('track');
  static const saveObject = SuggestedActionType('saveObject');
  static const deleteScreenshot = SuggestedActionType('deleteScreenshot');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestedActionType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

enum SuggestedActionStatus { suggested, completed, dismissed, failed }

final class SuggestedAction {
  const SuggestedAction({
    required this.id,
    required this.screenshotId,
    required this.type,
    required this.payload,
    required this.confidence,
    required this.status,
    required this.createdAt,
    this.extractedObjectId,
    this.completedAt,
    this.dismissedAt,
  });

  final String id;
  final String screenshotId;
  final String? extractedObjectId;
  final SuggestedActionType type;
  final JsonMap payload;
  final double confidence;
  final SuggestedActionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dismissedAt;
}
