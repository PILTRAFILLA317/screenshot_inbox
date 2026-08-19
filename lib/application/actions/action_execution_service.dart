import 'package:screenshot_inbox/core/platform/clock.dart';
import 'package:screenshot_inbox/core/debug/local_debug_log.dart';
import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';
import 'package:screenshot_inbox/domain/actions/calendar_event_policy.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action_repository.dart';
import 'package:screenshot_inbox/domain/extraction/extraction_repositories.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';

final class ActionExecutionService {
  ActionExecutionService({
    required this.calendar,
    required this.maps,
    required this.notifications,
    required this.urls,
    required this.clipboard,
    required this.actions,
    required this.objects,
    required this.screenshots,
    required this.lifecycleEvents,
    required this.clock,
    required this.ids,
    this.calendarPolicy = const CalendarEventPolicy(),
  });

  final CalendarGateway calendar;
  final MapsGateway maps;
  final NotificationGateway notifications;
  final UrlGateway urls;
  final ClipboardGateway clipboard;
  final SuggestedActionRepository actions;
  final ExtractedObjectRepository objects;
  final ScreenshotRepository screenshots;
  final LifecycleEventRepository lifecycleEvents;
  final Clock clock;
  final IdGenerator ids;
  final CalendarEventPolicy calendarPolicy;
  var _notificationsInitialized = false;

  Future<void> execute(SuggestedAction action) async {
    try {
      await _perform(action);
      final now = clock.now();
      await actions.save(
        action.copyWith(
          status: SuggestedActionStatus.completed,
          completedAt: now,
        ),
      );
      if (action.extractedObjectId != null) {
        await objects.setHandled(action.extractedObjectId!, true, now);
      }
      await screenshots.setLifecycleState(
        action.screenshotId,
        LifecycleState.handled,
      );
      await lifecycleEvents.appendAll([
        LifecycleEvent(
          id: ids.next(),
          screenshotId: action.screenshotId,
          type: LifecycleEventType.actionCompleted,
          timestamp: now,
          reason: '${_label(action)} was completed.',
          metadata: {'actionType': action.type.value},
        ),
      ]);
    } catch (error, stackTrace) {
      LocalDebugLog.event(
        'action.failed',
        metadata: {
          'actionId': action.id,
          'actionType': action.type.value,
          if (error is CalendarException) 'calendarFailure': error.code.name,
        },
        error: error,
        stackTrace: stackTrace,
      );
      await actions.save(action.copyWith(status: SuggestedActionStatus.failed));
      rethrow;
    }
  }

  Future<void> dismiss(SuggestedAction action) async {
    final now = clock.now();
    await actions.save(
      action.copyWith(
        status: SuggestedActionStatus.dismissed,
        dismissedAt: now,
      ),
    );
    if (action.extractedObjectId != null) {
      await objects.setHandled(action.extractedObjectId!, true, now);
    }
    await screenshots.setLifecycleState(
      action.screenshotId,
      LifecycleState.handled,
    );
    await lifecycleEvents.appendAll([
      LifecycleEvent(
        id: ids.next(),
        screenshotId: action.screenshotId,
        type: LifecycleEventType.actionCompleted,
        timestamp: now,
        reason: '${_label(action)} was dismissed.',
        metadata: {'actionType': action.type.value, 'dismissed': true},
      ),
    ]);
  }

  Future<void> _perform(SuggestedAction action) async {
    final payload = action.payload;
    if (action.type == SuggestedActionType.calendar) {
      final permission = await calendar.requestWritePermission();
      if (permission != CalendarPermissionState.granted &&
          permission != CalendarPermissionState.writeOnly) {
        throw const CalendarException(
          CalendarFailureCode.permissionDenied,
          'Calendar permission was not granted.',
        );
      }
      await calendar.createEvent(calendarPolicy.draftFromPayload(payload));
      return;
    }
    if (action.type == SuggestedActionType.reminder) {
      if (!_notificationsInitialized) {
        await notifications.initialize();
        _notificationsInitialized = true;
      }
      if (!await notifications.requestPermission()) {
        throw StateError('Notification permission was not granted.');
      }
      await notifications.schedule(
        id: action.id,
        title: _requiredString(payload, 'title'),
        body: (payload['body'] as String?) ?? 'Saved from Screenshot Inbox',
        at: _requiredDate(payload, 'remindAt'),
        payload: action.screenshotId,
      );
      return;
    }
    if (action.type == SuggestedActionType.maps) {
      await maps.openPlace(
        query: payload['query'] as String?,
        latitude: (payload['latitude'] as num?)?.toDouble(),
        longitude: (payload['longitude'] as num?)?.toDouble(),
        title: payload['title'] as String?,
      );
      return;
    }
    if (action.type == SuggestedActionType.openUrl ||
        action.type == SuggestedActionType.track) {
      final uri = Uri.tryParse(_requiredString(payload, 'url'));
      if (uri == null || !await urls.openExternal(uri)) {
        throw StateError('The URL could not be opened.');
      }
      return;
    }
    if (action.type == SuggestedActionType.searchWeb) {
      final uri = Uri.https('www.google.com', '/search', {
        'q': _requiredString(payload, 'query'),
      });
      if (!await urls.openExternal(uri)) {
        throw StateError('Web search could not be opened.');
      }
      return;
    }
    if (action.type == SuggestedActionType.copy) {
      await clipboard.copyText(_requiredString(payload, 'text'));
      return;
    }
    if (action.type == SuggestedActionType.saveObject) {
      final objectId =
          (payload['objectId'] as String?) ?? action.extractedObjectId;
      if (objectId == null) throw StateError('No extracted object to save.');
      await objects.setSaved(objectId, true, clock.now());
      return;
    }
    throw UnsupportedError('Unsupported action: ${action.type.value}');
  }

  static String _label(SuggestedAction action) =>
      (action.payload['label'] as String?) ?? action.type.value;
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
  static DateTime _requiredDate(Map<String, Object?> data, String key) =>
      _date(data[key]) ?? (throw StateError('Missing date: $key'));
  static String _requiredString(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw StateError('Missing value: $key');
  }
}
