import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_inbox/application/actions/action_execution_service.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';
import 'package:screenshot_inbox/domain/actions/calendar_event_policy.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action.dart';
import 'package:screenshot_inbox/domain/actions/suggested_action_repository.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';
import 'package:screenshot_inbox/domain/extraction/extraction_repositories.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle.dart';
import 'package:screenshot_inbox/domain/lifecycle/lifecycle_event_repository.dart';
import 'package:screenshot_inbox/domain/screenshots/screenshot_repository.dart';

import '../support/fixtures.dart';

void main() {
  const policy = CalendarEventPolicy();

  test('valid timed event has an explicit inferred end policy', () {
    final payload = policy.payloadFor(
      objectFixture(
        type: ExtractedObjectType.event,
        structuredData: const {
          'date': '2026-09-12',
          'time': '21:00',
          'startsAt': '2026-09-12T21:00:00',
          'venue': 'Riyadh Air Metropolitano',
          'timezone': 'Europe/Madrid',
        },
      ),
    )!;
    final draft = policy.draftFromPayload(payload);

    expect(draft.endsAt.difference(draft.startsAt), const Duration(hours: 2));
    expect(draft.endTimeInferred, isTrue);
    expect(draft.timeZone, 'Europe/Madrid');
  });

  test('all-day event uses a one-day half-open interval', () {
    final payload = policy.payloadFor(
      objectFixture(
        type: ExtractedObjectType.event,
        structuredData: const {
          'date': '2026-09-12',
          'startsAt': '2026-09-12T00:00:00',
        },
      ),
    )!;
    final draft = policy.draftFromPayload(payload);

    expect(draft.isAllDay, isTrue);
    expect(draft.endsAt.difference(draft.startsAt), const Duration(days: 1));
  });

  test('invalid or epoch-like dates never produce a calendar action', () {
    final invalid = objectFixture(
      type: ExtractedObjectType.event,
      structuredData: const {'startsAt': 'not-a-date'},
    );
    final epoch = objectFixture(
      type: ExtractedObjectType.event,
      structuredData: const {'startsAt': '1970-01-01T00:00:00'},
    );

    expect(policy.payloadFor(invalid), isNull);
    expect(policy.payloadFor(epoch), isNull);
  });

  test('permission denied is typed and action becomes failed', () async {
    final calendar = _Calendar(CalendarPermissionState.denied);
    final actions = _Actions();
    final service = _service(calendar, actions);

    await expectLater(
      service.execute(_calendarAction()),
      throwsA(
        isA<CalendarException>().having(
          (error) => error.code,
          'code',
          CalendarFailureCode.permissionDenied,
        ),
      ),
    );
    expect(actions.saved.single.status, SuggestedActionStatus.failed);
  });

  test('calendar service failure is propagated and not hidden', () async {
    final calendar = _Calendar(
      CalendarPermissionState.granted,
      error: const CalendarException(
        CalendarFailureCode.noWritableCalendar,
        'No writable calendar is available on this device.',
      ),
    );
    final service = _service(calendar, _Actions());

    await expectLater(
      service.execute(_calendarAction()),
      throwsA(
        isA<CalendarException>().having(
          (error) => error.code,
          'code',
          CalendarFailureCode.noWritableCalendar,
        ),
      ),
    );
  });

  test(
    'valid event reaches gateway with local wall time and timezone',
    () async {
      final calendar = _Calendar(CalendarPermissionState.granted);
      await _service(calendar, _Actions()).execute(_calendarAction());

      expect(calendar.created.single.startsAt.hour, 21);
      expect(calendar.created.single.timeZone, 'Europe/Madrid');
    },
  );
}

SuggestedAction _calendarAction() => SuggestedAction(
  id: 'action-1',
  screenshotId: 'screenshot-1',
  extractedObjectId: 'object-1',
  type: SuggestedActionType.calendar,
  payload: const {
    'label': 'Add to Calendar',
    'title': 'Bad Bunny',
    'startsAt': '2026-09-12T21:00:00',
    'endsAt': '2026-09-12T23:00:00',
    'timezone': 'Europe/Madrid',
    'endTimeInferred': true,
  },
  confidence: 0.9,
  status: SuggestedActionStatus.suggested,
  createdAt: DateTime.utc(2026, 8, 19),
);

ActionExecutionService _service(_Calendar calendar, _Actions actions) =>
    ActionExecutionService(
      calendar: calendar,
      maps: _UnusedMaps(),
      notifications: _UnusedNotifications(),
      urls: _UnusedUrls(),
      clipboard: _UnusedClipboard(),
      actions: actions,
      objects: _Objects(),
      screenshots: _Screenshots(),
      lifecycleEvents: _LifecycleEvents(),
      clock: FixedClock(DateTime.utc(2026, 8, 19, 12)),
      ids: SequenceIdGenerator(),
    );

final class _Calendar implements CalendarGateway {
  _Calendar(this.permission, {this.error});
  final CalendarPermissionState permission;
  final Object? error;
  final List<CalendarEventDraft> created = [];

  @override
  Future<String> createEvent(CalendarEventDraft event) async {
    if (error case final Object failure) throw failure;
    created.add(event);
    return 'event-1';
  }

  @override
  Future<CalendarPermissionState> requestWritePermission() async => permission;
}

final class _Actions implements SuggestedActionRepository {
  final List<SuggestedAction> saved = [];
  @override
  Future<List<SuggestedAction>> findForScreenshot(String screenshotId) async =>
      saved;
  @override
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<SuggestedAction> actions,
  ) async {}
  @override
  Future<void> save(SuggestedAction action) async => saved.add(action);
}

final class _Objects implements ExtractedObjectRepository {
  @override
  Future<void> setHandled(String id, bool handled, DateTime at) async {}
  @override
  Future<void> setSaved(String id, bool saved, DateTime at) async {}
  @override
  Future<List<ExtractedObject>> findForScreenshot(String screenshotId) async =>
      const [];
  @override
  Future<void> replaceForScreenshot(
    String screenshotId,
    List<ExtractedObject> objects,
  ) async {}
  @override
  Future<void> save(ExtractedObject object) async {}
}

final class _Screenshots implements ScreenshotRepository {
  @override
  Future<void> setLifecycleState(String id, LifecycleState state) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _LifecycleEvents implements LifecycleEventRepository {
  @override
  Future<void> appendAll(List<LifecycleEvent> events) async {}
  @override
  Future<List<LifecycleEvent>> findForScreenshot(String screenshotId) async =>
      const [];
}

final class _UnusedMaps implements MapsGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedNotifications implements NotificationGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedUrls implements UrlGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedClipboard implements ClipboardGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
