import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/import/domain/apply_import.dart';
import 'package:abfallkalender/features/import/domain/parsed_import.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:abfallkalender/features/upcoming/providers/app_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/test_container.dart';

void main() {
  test('loads from repository and exposes corrupt flag', () async {
    final repo = InMemoryEventRepository()..corruptOnLoad = true;
    final c = createTestContainer(events: repo);
    final data = await c.read(appDataProvider.future);
    expect(data.events, isEmpty);
    expect(c.read(appDataProvider.notifier).wasCorruptOnLoad, isTrue);
  });

  test('applyParsedImport saves, updates state and reschedules reminders', () async {
    final repo = InMemoryEventRepository();
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, gateway: gateway);
    await c.read(appDataProvider.future);

    final parsed = ParsedImport(
      sourceId: 'file:a',
      pickups: [RawPickup(date: DateTime(2026, 1, 5), rawName: 'Biotonne')],
      warnings: const [],
    );
    final out = await c.read(appDataProvider.notifier).applyParsedImport(parsed, ImportMode.merge);
    expect(out.imported, 1);
    expect(repo.saveCount, 1);
    expect(c.read(appDataProvider).value!.events.length, 1);
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled.length, 2); // Vortag + Abholtag mit Standardregeln
  });

  test('updateWasteType replaces type and reschedules', () async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
    ));
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, gateway: gateway);
    await c.read(appDataProvider.future);
    await c.read(appDataProvider.notifier).updateWasteType(
          const WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf', enabled: false),
        );
    expect(repo.data.wasteTypes.single.enabled, isFalse);
    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelAllCount, 1);
  });

  test('removeWasteType drops the type and its events, remembers the exclusion', () async {
    final repo = InMemoryEventRepository(AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's'),
        PickupEvent(date: DateTime(2026, 1, 6), wasteTypeId: 'rest', sourceId: 's'),
      ],
      wasteTypes: const [
        WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf'),
        WasteType(id: 'rest', displayName: 'Rest', color: 2, icon: 'trash'),
      ],
    ));
    final settings = InMemorySettingsRepository()..excludedTypeIds = {'glas'};
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, settings: settings, gateway: gateway);
    await c.read(appDataProvider.future);
    await c.read(appDataProvider.notifier).removeWasteType('bio');
    expect(repo.data.wasteTypes.map((t) => t.id), ['rest']);
    expect(repo.data.events.map((e) => e.wasteTypeId), ['rest']);
    expect(settings.excludedTypeIds, {'glas', 'bio'});
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled.map((n) => n.body), everyElement('Rest'));
  });

  test('removeSource drops its events and the types left without events', () async {
    final repo = InMemoryEventRepository(AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 'sample'),
        PickupEvent(date: DateTime(2026, 1, 6), wasteTypeId: 'rest', sourceId: 'sample'),
        PickupEvent(date: DateTime(2026, 1, 7), wasteTypeId: 'rest', sourceId: 'file:a'),
      ],
      wasteTypes: const [
        WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf'),
        WasteType(id: 'rest', displayName: 'Rest', color: 2, icon: 'trash'),
      ],
    ));
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, gateway: gateway);
    await c.read(appDataProvider.future);
    await c.read(appDataProvider.notifier).removeSource('sample');
    expect(repo.data.events.map((e) => e.key), ['2026-01-07|rest']);
    expect(repo.data.wasteTypes.map((t) => t.id), ['rest']);
    expect(gateway.cancelAllCount, 1);
  });

  test('clearAll empties data and cancels notifications', () async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
    ));
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(events: repo, gateway: gateway);
    await c.read(appDataProvider.future);
    await c.read(appDataProvider.notifier).clearAll();
    expect(repo.data.events, isEmpty);
    expect(repo.data.wasteTypes, isEmpty);
    expect(gateway.cancelAllCount, 1);
  });

  test('mutation before load completes does not overwrite stored data', () async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 'old')],
      wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
    ));
    final c = createTestContainer(events: repo);
    final parsed = ParsedImport(
      sourceId: 'file:new',
      pickups: [RawPickup(date: DateTime(2026, 2, 1), rawName: 'Altpapier')],
      warnings: const [],
    );
    // Deliberately no `await c.read(appDataProvider.future)` here.
    await c.read(appDataProvider.notifier).applyParsedImport(parsed, ImportMode.merge);
    expect(repo.data.events.map((e) => e.key), containsAll(['2026-01-05|bio', '2026-02-01|altpapier']));
  });
}
