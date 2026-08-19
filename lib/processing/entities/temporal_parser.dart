final class TemporalMatch {
  const TemporalMatch({
    required this.raw,
    required this.normalized,
    required this.start,
    required this.end,
    required this.confidence,
  });

  final String raw;
  final String normalized;
  final int start;
  final int end;
  final double confidence;
}

/// Centralized English/Spanish date and time parsing for deterministic MVP
/// extraction. It intentionally favors precision over recognizing every locale.
final class TemporalParser {
  const TemporalParser();

  List<TemporalMatch> dates(String text, DateTime reference) {
    final matches = <TemporalMatch>[];
    final occupied = <({int start, int end})>[];

    void add(RegExpMatch match, DateTime? date, double confidence) {
      if (date == null ||
          occupied.any(
            (range) => match.start < range.end && match.end > range.start,
          )) {
        return;
      }
      occupied.add((start: match.start, end: match.end));
      matches.add(
        TemporalMatch(
          raw: match.group(0)!,
          normalized: _date(date),
          start: match.start,
          end: match.end,
          confidence: confidence,
        ),
      );
    }

    for (final match in RegExp(
      r'\b(20\d{2})[-/](\d{1,2})[-/](\d{1,2})\b',
    ).allMatches(text)) {
      add(
        match,
        _safeDate(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        ),
        0.98,
      );
    }

    for (final match in RegExp(
      r'\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})\b',
    ).allMatches(text)) {
      var year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      add(
        match,
        _safeDate(year, int.parse(match.group(2)!), int.parse(match.group(1)!)),
        0.94,
      );
    }

    final monthPattern = _months.keys.join('|');
    final namedPattern = RegExp(
      '\\b(\\d{1,2})(?:st|nd|rd|th|º|ª)?\\s+(?:of|de\\s+)?($monthPattern)(?:\\s*,?\\s*(20\\d{2}))?\\b',
      caseSensitive: false,
      unicode: true,
    );
    for (final match in namedPattern.allMatches(text)) {
      final explicitYear = int.tryParse(match.group(3) ?? '');
      final month = _months[match.group(2)!.toLowerCase()]!;
      final day = int.parse(match.group(1)!);
      add(
        match,
        _safeDate(
          explicitYear ?? _yearForMissingYear(reference, month, day),
          month,
          day,
        ),
        match.group(3) == null ? 0.82 : 0.95,
      );
    }

    final relative = RegExp(
      r'\b(day after tomorrow|pasado mañana|tomorrow|mañana|today|hoy)\b',
      caseSensitive: false,
      unicode: true,
    );
    for (final match in relative.allMatches(text)) {
      final value = match.group(0)!.toLowerCase();
      final days = switch (value) {
        'day after tomorrow' || 'pasado mañana' => 2,
        'tomorrow' || 'mañana' => 1,
        _ => 0,
      };
      final local = reference.toLocal().add(Duration(days: days));
      add(match, DateTime(local.year, local.month, local.day), 0.88);
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches;
  }

  List<TemporalMatch> times(String text) {
    final matches = <TemporalMatch>[];
    final occupied = <({int start, int end})>[];

    void add(RegExpMatch match, int hour, int minute, double confidence) {
      if (hour > 23 ||
          minute > 59 ||
          occupied.any(
            (range) => match.start < range.end && match.end > range.start,
          )) {
        return;
      }
      occupied.add((start: match.start, end: match.end));
      matches.add(
        TemporalMatch(
          raw: match.group(0)!,
          normalized:
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
          start: match.start,
          end: match.end,
          confidence: confidence,
        ),
      );
    }

    for (final match in RegExp(
      r'\b(1[0-2]|0?[1-9])(?::([0-5]\d))?\s?(a\.?m\.?|p\.?m\.?)\b',
      caseSensitive: false,
    ).allMatches(text)) {
      var hour = int.parse(match.group(1)!);
      final period = match.group(3)!.toLowerCase();
      if (period.startsWith('p') && hour != 12) hour += 12;
      if (period.startsWith('a') && hour == 12) hour = 0;
      add(match, hour, int.tryParse(match.group(2) ?? '') ?? 0, 0.96);
    }

    for (final match in RegExp(
      r'(?<!\d)([01]?\d|2[0-3])[:h.]([0-5]\d)(?!\d)',
      caseSensitive: false,
    ).allMatches(text)) {
      add(match, int.parse(match.group(1)!), int.parse(match.group(2)!), 0.95);
    }

    for (final match in RegExp(
      r'\b(?:at|a las)\s+([01]?\d|2[0-3])\b',
      caseSensitive: false,
    ).allMatches(text)) {
      add(match, int.parse(match.group(1)!), 0, 0.78);
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches;
  }

  DateTime? combine(String? date, String? time) {
    if (date == null) return null;
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return null;
    final parts = time?.split(':');
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parts == null ? 0 : int.parse(parts[0]),
      parts == null ? 0 : int.parse(parts[1]),
    );
  }

  static DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static int _yearForMissingYear(DateTime reference, int month, int day) {
    final candidate = _safeDate(reference.year, month, day);
    if (candidate == null) return reference.year;
    final referenceDay = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    return candidate.isBefore(referenceDay.subtract(const Duration(days: 30)))
        ? reference.year + 1
        : reference.year;
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static const _months = <String, int>{
    'january': 1,
    'jan': 1,
    'enero': 1,
    'february': 2,
    'feb': 2,
    'febrero': 2,
    'march': 3,
    'mar': 3,
    'marzo': 3,
    'april': 4,
    'apr': 4,
    'abril': 4,
    'may': 5,
    'mayo': 5,
    'june': 6,
    'jun': 6,
    'junio': 6,
    'july': 7,
    'jul': 7,
    'julio': 7,
    'august': 8,
    'aug': 8,
    'agosto': 8,
    'september': 9,
    'sep': 9,
    'septiembre': 9,
    'october': 10,
    'oct': 10,
    'octubre': 10,
    'november': 11,
    'nov': 11,
    'noviembre': 11,
    'december': 12,
    'dec': 12,
    'diciembre': 12,
  };
}
