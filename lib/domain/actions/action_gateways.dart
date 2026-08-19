enum CalendarPermissionState {
  notDetermined,
  restricted,
  denied,
  writeOnly,
  granted,
}

final class CalendarEventDraft {
  const CalendarEventDraft({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.description,
    this.location,
    this.url,
    this.isAllDay = false,
    this.timeZone,
    this.endTimeInferred = false,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? description;
  final String? location;
  final String? url;
  final bool isAllDay;
  final String? timeZone;
  final bool endTimeInferred;
}

enum CalendarFailureCode {
  permissionDenied,
  noWritableCalendar,
  invalidPayload,
  platformFailure,
}

final class CalendarException implements Exception {
  const CalendarException(this.code, this.message, [this.cause]);

  final CalendarFailureCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

abstract interface class CalendarGateway {
  Future<CalendarPermissionState> requestWritePermission();

  Future<String> createEvent(CalendarEventDraft event);
}

abstract interface class MapsGateway {
  Future<void> openPlace({
    String? query,
    double? latitude,
    double? longitude,
    String? title,
  });
}

abstract interface class NotificationGateway {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  });
}

abstract interface class UrlGateway {
  Future<bool> openExternal(Uri uri);
}

abstract interface class ClipboardGateway {
  Future<void> copyText(String text);
}
