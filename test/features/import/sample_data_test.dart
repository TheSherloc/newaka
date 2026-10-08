import 'package:abfallkalender/features/import/domain/sample_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final from = DateTime(2026, 10, 8, 14, 30);
  final parsed = sampleImport(from: from);

  test('covers four types for twelve months starting at the given day', () {
    expect(parsed.sourceId, SampleData.sourceId);
    expect(parsed.distinctRawNames, unorderedEquals(['Restmüll', 'Biotonne', 'Papiertonne', 'Gelber Sack']));
    expect(parsed.firstDate.isBefore(DateTime(2026, 10, 8)), isFalse);
    expect(parsed.lastDate.isAfter(DateTime(2027, 10, 8)), isFalse);
    expect(parsed.lastDate.isAfter(DateTime(2027, 9, 8)), isTrue);
    expect(parsed.warnings, isEmpty);
  });

  test('uses the documented intervals per type', () {
    int countOf(String name) => parsed.pickups.where((p) => p.rawName == name).length;
    expect(countOf('Biotonne'), inInclusiveRange(52, 53));
    expect(countOf('Restmüll'), inInclusiveRange(26, 27));
    expect(countOf('Gelber Sack'), inInclusiveRange(26, 27));
    expect(countOf('Papiertonne'), inInclusiveRange(13, 14));
  });

  test('dates are plain days without a time of day', () {
    expect(parsed.pickups.every((p) => p.date.hour == 0 && p.date.minute == 0), isTrue);
  });

  test('keeps plain days and weekdays across the autumn DST change', () {
    // Start shortly before 25 Oct 2026 so the week offsets cross the clock change.
    final dst = sampleImport(from: DateTime(2026, 10, 22));
    expect(dst.pickups.every((p) => p.date.hour == 0 && p.date.minute == 0), isTrue);
    for (final (name, _, weekday, _) in SampleData.types) {
      expect(dst.pickups.where((p) => p.rawName == name).map((p) => p.date.weekday).toSet(), {weekday},
          reason: name);
    }
  });

  test('is deterministic for the same start day', () {
    final again = sampleImport(from: DateTime(2026, 10, 8, 23, 59));
    expect(again.pickups.map((p) => '${p.date}|${p.rawName}'), parsed.pickups.map((p) => '${p.date}|${p.rawName}'));
  });
}
