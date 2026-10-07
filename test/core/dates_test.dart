import 'package:abfallkalender/core/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly strips time', () {
    expect(DateTime(2026, 3, 5, 14, 30).dateOnly, DateTime(2026, 3, 5));
  });

  test('isoDate pads', () {
    expect(DateTime(2026, 1, 2).isoDate, '2026-01-02');
  });

  test('daysBetween across DST switch is calendar days', () {
    expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    expect(daysBetween(DateTime(2026, 3, 30), DateTime(2026, 3, 28)), -2);
  });

  test('parseIsoDate', () {
    expect(parseIsoDate('2026-01-02'), DateTime(2026, 1, 2));
    expect(parseIsoDate('2026-13-02'), isNull);
    expect(parseIsoDate('02.01.2026'), isNull);
  });

  test('parseGermanDate', () {
    expect(parseGermanDate('02.01.2026'), DateTime(2026, 1, 2));
    expect(parseGermanDate(' 2.1.2026 '), DateTime(2026, 1, 2));
    expect(parseGermanDate('31.02.2026'), isNull);
  });

  test('parseFlexibleDate accepts both', () {
    expect(parseFlexibleDate('2026-01-02'), DateTime(2026, 1, 2));
    expect(parseFlexibleDate('02.01.2026'), DateTime(2026, 1, 2));
    expect(parseFlexibleDate('Freitag'), isNull);
  });
}
