import 'dart:io';

import 'package:abfallkalender/core/result.dart';
import 'package:abfallkalender/features/import/domain/ics_parser.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:flutter_test/flutter_test.dart';

List<RawPickup> okValue(Result<List<RawPickup>> r) =>
    r.when(ok: (v, _) => v, err: (m) => throw StateError(m));

void main() {
  final parser = IcsParser();

  test('looksLikeIcs', () {
    expect(IcsParser.looksLikeIcs('BEGIN:VCALENDAR\r\nEND:VCALENDAR'), isTrue);
    expect(IcsParser.looksLikeIcs('Datum;Art'), isFalse);
  });

  test('parses fixture with 94 events', () {
    final text = File('test/fixtures/augsburg_2026.ics').readAsStringSync();
    final pickups = okValue(parser.parse(text));
    expect(pickups.length, 94);
    expect(pickups.first.date, DateTime(2026, 1, 2));
    expect(pickups.first.rawName, 'Abfuhr: Biotonne');
    expect(pickups.first.note, contains('6.30 Uhr'));
    expect(pickups.map((p) => p.rawName).toSet().length, 5);
  });

  test('unfolds continuation lines and unescapes text', () {
    const text = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20260105T060000
SUMMARY:Abfuhr: Wertstofftonne \\/ Gel
 ber Container\\, Hof
DESCRIPTION:Zeile 1\\nZeile 2\\; Ende
END:VEVENT
END:VCALENDAR
''';
    final p = okValue(parser.parse(text)).single;
    expect(p.rawName, 'Abfuhr: Wertstofftonne / Gelber Container, Hof');
    expect(p.note, 'Zeile 1\nZeile 2; Ende');
  });

  test('handles VALUE=DATE, TZID and UTC forms', () {
    const text = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260102
SUMMARY:A
END:VEVENT
BEGIN:VEVENT
DTSTART;TZID=Europe/Berlin:20260103T060000
SUMMARY:B
END:VEVENT
BEGIN:VEVENT
DTSTART:20260104T050000Z
SUMMARY:C
END:VEVENT
END:VCALENDAR
''';
    final ps = okValue(parser.parse(text));
    expect(ps.map((p) => p.date).toList(),
        [DateTime(2026, 1, 2), DateTime(2026, 1, 3), DateTime(2026, 1, 4)]);
  });

  test('skips events without date or summary and reports warning', () {
    const text = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Ohne Datum
END:VEVENT
BEGIN:VEVENT
DTSTART:20260104
END:VEVENT
BEGIN:VEVENT
DTSTART:20260105
SUMMARY:Gültig
END:VEVENT
END:VCALENDAR
''';
    final r = parser.parse(text);
    final warnings = r.when(ok: (_, w) => w, err: (_) => <String>[]);
    expect(okValue(r).length, 1);
    expect(warnings.single, contains('2'));
  });

  test('returns Err when no events', () {
    final r = parser.parse('BEGIN:VCALENDAR\nEND:VCALENDAR');
    expect(r.isOk, isFalse);
    expect(r.when(ok: (_, _) => '', err: (m) => m), contains('keine Termine'));
  });

  test('ignores properties of nested VALARM components', () {
    const text = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20260105
SUMMARY:Abfuhr: Biotonne
DESCRIPTION:Tonne bereitstellen
BEGIN:VALARM
ACTION:DISPLAY
DESCRIPTION:Erinnerung
SUMMARY:Alarm
TRIGGER:-PT12H
END:VALARM
END:VEVENT
END:VCALENDAR
''';
    final p = okValue(parser.parse(text)).single;
    expect(p.rawName, 'Abfuhr: Biotonne');
    expect(p.note, 'Tonne bereitstellen');
  });
}
