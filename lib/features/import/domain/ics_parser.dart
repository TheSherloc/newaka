import '../../../core/result.dart';
import 'raw_pickup.dart';

class IcsParser {
  static const noEventsMessage =
      'Die ICS-Datei enthält keine Termine. Erwartet werden VEVENT-Einträge mit DTSTART und SUMMARY.';

  static bool looksLikeIcs(String text) => text.contains('BEGIN:VCALENDAR');

  static final _dateStart = RegExp(r'^(\d{4})(\d{2})(\d{2})');
  static final _escape = RegExp(r'\\(.)');

  Result<List<RawPickup>> parse(String text) {
    final pickups = <RawPickup>[];
    var skipped = 0;
    var inEvent = false;
    var nested = 0;
    String? dtstart;
    String? summary;
    String? description;

    for (final line in _unfold(text)) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        nested = 0;
        dtstart = null;
        summary = null;
        description = null;
        continue;
      }
      if (line == 'END:VEVENT') {
        inEvent = false;
        final date = dtstart == null ? null : _parseDate(dtstart);
        if (date == null || summary == null || summary.trim().isEmpty) {
          skipped++;
        } else {
          pickups.add(RawPickup(date: date, rawName: summary.trim(), note: description));
        }
        continue;
      }
      if (!inEvent) continue;

      // Handle nested components (e.g., VALARM)
      if (line.startsWith('BEGIN:')) {
        nested++;
        continue;
      }
      if (line.startsWith('END:') && nested > 0) {
        nested--;
        continue;
      }

      // Skip properties inside nested components
      if (nested > 0) continue;

      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final name = line.substring(0, colon).split(';').first.toUpperCase();
      final value = line.substring(colon + 1);
      switch (name) {
        case 'DTSTART':
          dtstart = value;
        case 'SUMMARY':
          summary = _unescape(value);
        case 'DESCRIPTION':
          description = _unescape(value);
      }
    }

    if (pickups.isEmpty) return const Err(noEventsMessage);
    return Ok(
      pickups,
      warnings: skipped > 0 ? ['$skipped Einträge ohne Datum oder Titel übersprungen.'] : const [],
    );
  }

  List<String> _unfold(String text) {
    final out = <String>[];
    for (final line in text.split(RegExp(r'\r?\n'))) {
      if ((line.startsWith(' ') || line.startsWith('\t')) && out.isNotEmpty) {
        out[out.length - 1] = out.last + line.substring(1);
      } else {
        out.add(line);
      }
    }
    return out;
  }

  DateTime? _parseDate(String value) {
    final m = _dateStart.firstMatch(value.trim());
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, mo, d);
    if (date.month != mo || date.day != d) return null;
    return date;
  }

  String _unescape(String value) => value.replaceAllMapped(_escape, (m) {
        final c = m[1]!;
        return (c == 'n' || c == 'N') ? '\n' : c;
      });
}
