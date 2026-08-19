import 'package:device_calendar_plus/device_calendar_plus.dart' as device;
import 'package:flutter/foundation.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';

final class DeviceCalendarGateway implements CalendarGateway {
  DeviceCalendarGateway({device.DeviceCalendar? calendar})
    : _calendar = calendar ?? device.DeviceCalendar.instance;

  final device.DeviceCalendar _calendar;

  @override
  Future<CalendarPermissionState> requestWritePermission() async {
    try {
      // Android needs read access to resolve the writable default calendar.
      final status = await _calendar.requestPermissions(
        level: defaultTargetPlatform == TargetPlatform.android
            ? device.CalendarAccessLevel.full
            : device.CalendarAccessLevel.writeOnly,
      );
      return CalendarPermissionState.values.byName(status.name);
    } on Object catch (error) {
      throw CalendarException(
        CalendarFailureCode.platformFailure,
        'Calendar permission could not be checked.',
        error,
      );
    }
  }

  @override
  Future<String> createEvent(CalendarEventDraft event) async {
    try {
      return await _calendar.createEvent(
        title: event.title,
        startDate: event.startsAt,
        endDate: event.endsAt,
        description: event.description,
        location: event.location,
        url: event.url,
        isAllDay: event.isAllDay,
        timeZone: event.isAllDay ? null : event.timeZone,
      );
    } on device.DeviceCalendarException catch (error) {
      final noCalendar = error.message.toLowerCase().contains('calendar');
      throw CalendarException(
        noCalendar
            ? CalendarFailureCode.noWritableCalendar
            : CalendarFailureCode.platformFailure,
        noCalendar
            ? 'No writable calendar is available on this device.'
            : 'Calendar could not create the event.',
        error,
      );
    } on Object catch (error) {
      throw CalendarException(
        CalendarFailureCode.platformFailure,
        'Calendar could not create the event.',
        error,
      );
    }
  }
}
