import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/import/domain/apply_import.dart';
import 'package:abfallkalender/features/import/domain/parsed_import.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedImport parsed(String source, List<RawPickup> pickups) =>
    ParsedImport(sourceId: source, pickups: pickups, warnings: const []);

void main() {
  test('creates waste types with defaults and dedupes duplicate rows', () {
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Abfuhr: Biotonne'),
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne'),
      RawPickup(date: DateTime(2026, 1, 9), rawName: 'Restmüll Tonne'),
    ]);
    final out = applyImport(current: AppData.empty, parsed: p, mode: ImportMode.merge);
    expect(out.data.events.length, 2);
    expect(out.imported, 2);
    expect(out.data.wasteTypes.map((t) => t.id), containsAll(['biotonne', 'restmuell_tonne']));
    expect(out.newWasteTypes.length, 2);
    expect(out.data.wasteTypes.firstWhere((t) => t.id == 'biotonne').color, 0xFF6D4C41);
  });

  test('merge keeps other sources, replaces same source (handles removals)', () {
    final current = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 'file:a'),
        PickupEvent(date: DateTime(2026, 1, 3), wasteTypeId: 'biotonne', sourceId: 'file:a'),
        PickupEvent(date: DateTime(2026, 2, 1), wasteTypeId: 'papier', sourceId: 'url:x'),
      ],
      wasteTypes: const [
        WasteType(id: 'biotonne', displayName: 'Meine Bio', color: 1, icon: 'leaf'),
        WasteType(id: 'papier', displayName: 'Papier', color: 2, icon: 'paper'),
      ],
    );
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne'),
      RawPickup(date: DateTime(2026, 1, 10), rawName: 'Biotonne'),
    ]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.merge);
    final keys = out.data.events.map((e) => e.key).toList();
    expect(keys, containsAll(['2026-01-02|biotonne', '2026-01-10|biotonne', '2026-02-01|papier']));
    expect(keys, isNot(contains('2026-01-03|biotonne')));
    expect(out.data.events.length, 3);
    // user customisations survive
    expect(out.data.wasteTypes.firstWhere((t) => t.id == 'biotonne').displayName, 'Meine Bio');
    expect(out.newWasteTypes, isEmpty);
  });

  test('existing event with same key from another source wins', () {
    final current = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 'url:x', note: 'alt'),
      ],
      wasteTypes: const [WasteType(id: 'biotonne', displayName: 'Bio', color: 1, icon: 'leaf')],
    );
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne', note: 'neu'),
    ]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.merge);
    expect(out.data.events.single.note, 'alt');
  });

  test('replace drops all events and waste types that no longer have events', () {
    final current = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 2, 1), wasteTypeId: 'papier', sourceId: 'url:x'),
      ],
      wasteTypes: const [WasteType(id: 'papier', displayName: 'Papier', color: 2, icon: 'paper')],
    );
    final p = parsed('file:a', [RawPickup(date: DateTime(2026, 1, 2), rawName: 'Biotonne')]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.replace);
    expect(out.data.events.single.wasteTypeId, 'biotonne');
    expect(out.data.wasteTypes.map((t) => t.id), ['biotonne']);
  });

  test('replace keeps customisations of types that reappear', () {
    final current = AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 'file:a')],
      wasteTypes: const [WasteType(id: 'biotonne', displayName: 'Meine Bio', color: 7, icon: 'tree')],
    );
    final p = parsed('file:a', [RawPickup(date: DateTime(2026, 3, 2), rawName: 'Biotonne')]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.replace);
    expect(out.data.wasteTypes.single.displayName, 'Meine Bio');
    expect(out.data.wasteTypes.single.color, 7);
  });

  test('merge re-import of the same source without a type removes that type', () {
    final current = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 'file:a'),
        PickupEvent(date: DateTime(2026, 1, 9), wasteTypeId: 'restmuell', sourceId: 'file:a'),
      ],
      wasteTypes: const [
        WasteType(id: 'biotonne', displayName: 'Bio', color: 1, icon: 'leaf'),
        WasteType(id: 'restmuell', displayName: 'Rest', color: 2, icon: 'trash'),
      ],
    );
    final p = parsed('file:a', [RawPickup(date: DateTime(2026, 1, 9), rawName: 'Restmüll')]);
    final out = applyImport(current: current, parsed: p, mode: ImportMode.merge);
    expect(out.data.wasteTypes.map((t) => t.id), ['restmuell']);
  });

  test('events are sorted by date', () {
    final p = parsed('file:a', [
      RawPickup(date: DateTime(2026, 3, 1), rawName: 'A'),
      RawPickup(date: DateTime(2026, 1, 1), rawName: 'B'),
    ]);
    final out = applyImport(current: AppData.empty, parsed: p, mode: ImportMode.merge);
    expect(out.data.events.first.date, DateTime(2026, 1, 1));
  });
}
