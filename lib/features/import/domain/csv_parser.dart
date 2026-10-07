import '../../../core/dates.dart';
import '../../../core/result.dart';
import 'raw_pickup.dart';

class CsvParser {
  static const emptyMessage = 'Die Datei ist leer.';
  static const noDateColumnMessage =
      'Die Datei enthält keine erkennbaren Termine. Erwartet wird eine Spalte mit Datum (z. B. 02.01.2026) und eine mit der Abfuhrart.';
  static const noTypeColumnMessage =
      'Die Datei enthält keine Spalte mit der Abfuhrart neben der Datumsspalte.';

  static const _dateHeaders = {'datum', 'date', 'termin', 'tag'};
  static const _typeHeaders = {
    'abfuhrart', 'abfallart', 'art', 'typ', 'type', 'fraktion', 'tonne', 'abfall', 'kategorie',
  };
  static const _weekdays = {
    'montag', 'dienstag', 'mittwoch', 'donnerstag', 'freitag', 'samstag', 'sonntag',
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    'mo', 'di', 'mi', 'do', 'fr', 'sa', 'so',
  };

  Result<List<RawPickup>> parse(String text) {
    final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const Err(emptyMessage);

    final delimiter = _detectDelimiter(lines.first);
    final rows = lines.map((l) => _splitLine(l, delimiter)).toList();

    final hasHeader = rows.first.every((c) => parseFlexibleDate(c) == null);
    final header = hasHeader ? rows.first.map((h) => h.trim().toLowerCase()).toList() : null;
    final dataRows = hasHeader ? rows.sublist(1) : rows;
    if (dataRows.isEmpty) return const Err(noDateColumnMessage);

    final dateCol = _findDateColumn(header, dataRows);
    if (dateCol == null) return const Err(noDateColumnMessage);
    final typeCol = _findTypeColumn(header, dataRows, dateCol);
    if (typeCol == null) return const Err(noTypeColumnMessage);

    final pickups = <RawPickup>[];
    var skipped = 0;
    for (final row in dataRows) {
      if (row.length <= dateCol || row.length <= typeCol) {
        skipped++;
        continue;
      }
      final date = parseFlexibleDate(row[dateCol]);
      final name = row[typeCol].trim();
      if (date == null || name.isEmpty) {
        skipped++;
        continue;
      }
      pickups.add(RawPickup(date: date, rawName: name));
    }

    if (pickups.isEmpty) return const Err(noDateColumnMessage);
    return Ok(
      pickups,
      warnings: skipped > 0 ? ['$skipped Zeilen ohne gültiges Datum oder Abfuhrart übersprungen.'] : const [],
    );
  }

  String _detectDelimiter(String line) {
    var best = ';';
    var bestCount = -1;
    for (final d in [';', ',', '\t']) {
      final count = d.allMatches(line).length;
      if (count > bestCount) {
        best = d;
        bestCount = count;
      }
    }
    return best;
  }

  List<String> _splitLine(String line, String delimiter) {
    final fields = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(c);
        }
      } else if (c == '"') {
        inQuotes = true;
      } else if (c == delimiter) {
        fields.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    fields.add(buf.toString());
    return fields.map((f) => f.trim()).toList();
  }

  int _columnCount(List<List<String>> rows) =>
      rows.fold(0, (max, r) => r.length > max ? r.length : max);

  bool _majority(List<List<String>> rows, int col, bool Function(String) test) {
    var hits = 0;
    var total = 0;
    for (final r in rows) {
      if (r.length <= col) continue;
      total++;
      if (test(r[col])) hits++;
    }
    return total > 0 && hits * 2 >= total;
  }

  int? _findDateColumn(List<String>? header, List<List<String>> rows) {
    if (header != null) {
      final idx = header.indexWhere(_dateHeaders.contains);
      if (idx >= 0 && _majority(rows, idx, (v) => parseFlexibleDate(v) != null)) return idx;
    }
    for (var c = 0; c < _columnCount(rows); c++) {
      if (_majority(rows, c, (v) => parseFlexibleDate(v) != null)) return c;
    }
    return null;
  }

  int? _findTypeColumn(List<String>? header, List<List<String>> rows, int dateCol) {
    bool isTypeValue(String v) {
      final t = v.trim();
      return t.isNotEmpty &&
          parseFlexibleDate(t) == null &&
          !_weekdays.contains(t.toLowerCase().replaceAll('.', ''));
    }

    if (header != null) {
      final idx = header.indexWhere(_typeHeaders.contains);
      if (idx >= 0 && idx != dateCol) return idx;
    }
    for (var c = 0; c < _columnCount(rows); c++) {
      if (c == dateCol) continue;
      if (_majority(rows, c, isTypeValue)) return c;
    }
    return null;
  }
}
