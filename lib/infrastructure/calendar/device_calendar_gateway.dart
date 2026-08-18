import 'package:device_calendar_plus/device_calendar_plus.dart' as device;
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';

final class DeviceCalendarGateway implements CalendarGateway {
  DeviceCalendarGateway({device.DeviceCalendar? calendar})
    : _calendar = calendar ?? device.DeviceCalendar.instance;

  final device.DeviceCalendar _calendar;

  @override
  Future<CalendarPermissionState> requestWritePermission() async {
    final status = await _calendar.requestPermissions(
      level: device.CalendarAccessLevel.writeOnly,
    );
    return CalendarPermissionState.values.byName(status.name);
  }

  @override
  Future<String> createEvent(CalendarEventDraft event) => _calendar.createEvent(
    title: event.title,
    startDate: event.startsAt,
    endDate: event.endsAt,
    description: event.description,
    location: event.location,
    url: event.url,
    isAllDay: event.isAllDay,
  );
}
