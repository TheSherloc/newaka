import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/import/domain/import_selection.dart';
import 'package:abfallkalender/features/import/domain/parsed_import.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedImport parsed(List<RawPickup> pickups) =>
    ParsedImport(sourceId: 'file:a', pickups: pickups, warnings: const ['w']);

const bio = WasteType(id: 'biotonne', displayName: 'Biotonne', color: 1, icon: 'leaf');
const papier = WasteType(id: 'altpapier', displayName: 'Altpapier', color: 2, icon: 'paper');

void main() {
  final p = parsed([
    RawPickup(date: DateTime(2026, 1, 2), rawName: 'Abfuhr: Biotonne'),
    RawPickup(date: DateTime(2026, 1, 9), rawName: 'Biotonne'),
    RawPickup(date: DateTime(2026, 1, 5), rawName: 'Altpapier'),
  ]);

  test('countByType counts pickups per resolved type id', () {
    final counts = countByType(p, const [bio, papier]);
    expect(counts.map((c) => c.type.id), ['biotonne', 'altpapier']);
    expect(counts.map((c) => c.count), [2, 1]);
  });

  test('filterParsedImport drops excluded types and keeps warnings', () {
    final f = filterParsedImport(p, {'biotonne'});
    expect(f.pickups.map((x) => x.rawName), ['Altpapier']);
    expect(f.sourceId, 'file:a');
    expect(f.warnings, ['w']);
  });

  test('filterParsedImport with empty exclusion returns same pickups', () {
    expect(filterParsedImport(p, const {}).pickups.length, 3);
  });

  test('mergeExclusions replaces decisions for types seen in this import', () {
    final merged = mergeExclusions(
      stored: {'biotonne', 'glas'},
      seenInImport: {'biotonne', 'altpapier'},
      excludedNow: {'altpapier'},
    );
    expect(merged, {'glas', 'altpapier'});
  });
}
