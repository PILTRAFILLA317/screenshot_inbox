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
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? description;
  final String? location;
  final String? url;
  final bool isAllDay;
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
