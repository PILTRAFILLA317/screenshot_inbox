import 'package:screenshot_inbox/core/utils/json_types.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';
import 'package:screenshot_inbox/domain/extraction/extracted_object.dart';

final class CalendarEventPolicy {
  const CalendarEventPolicy({
    this.defaultTimedDuration = const Duration(hours: 2),
  });

  final Duration defaultTimedDuration;

  JsonMap? payloadFor(ExtractedObject object) {
    final data = object.structuredData;
    final startsAt = _parseDate(data['startsAt']);
    if (startsAt == null || !_sane(startsAt) || object.title.trim().isEmpty) {
      return null;
    }
    final isAllDay = data['time'] == null;
    final explicitEnd = _parseDate(data['endsAt']);
    final endsAt =
        explicitEnd ??
        startsAt.add(isAllDay ? const Duration(days: 1) : defaultTimedDuration);
    final location = _firstString(data, const ['venue', 'city']);
    final reliable =
        _reliable(object, 'title') &&
        (_reliable(object, 'date') || object.confidence >= 0.85);
    return {
      'label': reliable ? 'Add to Calendar' : 'Review event',
      'title': object.title.trim(),
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'isAllDay': isAllDay,
      'endTimeInferred': explicitEnd == null,
      'defaultDurationMinutes': isAllDay
          ? const Duration(days: 1).inMinutes
          : defaultTimedDuration.inMinutes,
      'location': ?location,
      if (data['timezone'] case final String timezone) 'timezone': timezone,
    };
  }

  CalendarEventDraft draftFromPayload(JsonMap payload) {
    final title = payload['title'];
    final startsAt = _parseDate(payload['startsAt']);
    final endsAt = _parseDate(payload['endsAt']);
    if (title is! String || title.trim().isEmpty) {
      throw const CalendarException(
        CalendarFailureCode.invalidPayload,
        'Review the event title before adding it to Calendar.',
      );
    }
    if (startsAt == null || !_sane(startsAt)) {
      throw const CalendarException(
        CalendarFailureCode.invalidPayload,
        'Review the event date before adding it to Calendar.',
      );
    }
    if (endsAt == null || !endsAt.isAfter(startsAt)) {
      throw const CalendarException(
        CalendarFailureCode.invalidPayload,
        'The event end must be after its start.',
      );
    }
    final timezone = payload['timezone'];
    return CalendarEventDraft(
      title: title.trim(),
      startsAt: startsAt,
      endsAt: endsAt,
      location: _optionalString(payload['location']),
      description: _optionalString(payload['description']),
      url: _optionalString(payload['url']),
      isAllDay: payload['isAllDay'] == true,
      timeZone: timezone is String && timezone.contains('/') ? timezone : null,
      endTimeInferred: payload['endTimeInferred'] == true,
    );
  }

  static bool _reliable(ExtractedObject object, String field) {
    final raw = object.structuredData['_fieldMetadata'];
    if (raw is! Map) return object.confidence >= 0.85;
    final metadata = raw[field];
    if (metadata is! Map) return object.confidence >= 0.85;
    final source = metadata['source'];
    if (source == 'userEdited' || source == 'userConfirmed') return true;
    final confidence = metadata['confidence'];
    final evidence = metadata['evidence'];
    return confidence is num &&
        confidence >= 0.72 &&
        evidence is List &&
        evidence.isNotEmpty;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  static bool _sane(DateTime value) => value.year >= 2000 && value.year <= 2100;

  static String? _firstString(JsonMap data, List<String> keys) {
    for (final key in keys) {
      final value = _optionalString(data[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String? _optionalString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
