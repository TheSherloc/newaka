import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/settings/ui/data_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

void main() {
  testWidgets('shows subscription state and removes it', (tester) async {
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: 'https://a.example/x.ics', lastFetched: DateTime(2026, 1, 1, 8), lastError: 'Status 500');
    await pumpApp(tester, const Scaffold(body: DataSection()), overrides: testOverrides(settings: settings));
    expect(find.text('https://a.example/x.ics'), findsOneWidget);
    expect(find.textContaining('Fehler: Status 500'), findsOneWidget);
    await tester.tap(find.text('Abo entfernen'));
    await tester.pumpAndSettle();
    expect(settings.subscription, isNull);
    expect(find.text('Kein Abo eingerichtet'), findsOneWidget);
  });

  testWidgets('sample data opens the import preview and imports on confirm', (tester) async {
    final repo = InMemoryEventRepository();
    await pumpApp(tester, const Scaffold(body: DataSection()), overrides: testOverrides(events: repo));
    await tester.tap(find.text('Beispieldaten laden'));
    await tester.pumpAndSettle();
    expect(find.text('Import prüfen'), findsOneWidget);
    expect(find.text('Biotonne'), findsOneWidget);
    await tester.tap(find.text('Importieren'));
    await tester.pumpAndSettle();
    expect(repo.data.wasteTypes.map((t) => t.displayName), containsAll(['Restmüll', 'Biotonne', 'Papiertonne', 'Gelber Sack']));
    expect(repo.data.events.length, greaterThan(100));
    expect(repo.data.events.every((e) => e.sourceId == 'sample'), isTrue);
  });

  testWidgets('preview offers a single Importieren button while no data exists', (tester) async {
    final repo = InMemoryEventRepository();
    await pumpApp(tester, const Scaffold(body: DataSection()), overrides: testOverrides(events: repo));
    await tester.tap(find.text('Beispieldaten laden'));
    await tester.pumpAndSettle();
    expect(find.text('Zusammenführen'), findsNothing);
    expect(find.text('Bestehende ersetzen'), findsNothing);
    await tester.tap(find.text('Importieren'));
    await tester.pumpAndSettle();
    expect(repo.data.events, isNotEmpty);
  });

  testWidgets('preview offers merge and replace once data exists', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 6), wasteTypeId: 'glas', sourceId: 'file:a')],
      wasteTypes: const [WasteType(id: 'glas', displayName: 'Glas', color: 2, icon: 'bottle')],
    ));
    await pumpApp(tester, const Scaffold(body: DataSection()), overrides: testOverrides(events: repo));
    await tester.tap(find.text('Beispieldaten laden'));
    await tester.pumpAndSettle();
    expect(find.text('Zusammenführen'), findsOneWidget);
    expect(find.text('Bestehende ersetzen'), findsOneWidget);
    expect(find.text('Importieren'), findsNothing);
  });

  testWidgets('sample preview choices do not touch the stored import exclusion', (tester) async {
    final settings = InMemorySettingsRepository()..excludedTypeIds = {'glas'};
    await pumpApp(tester, const Scaffold(body: DataSection()), overrides: testOverrides(settings: settings));
    await tester.tap(find.text('Beispieldaten laden'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.tap(find.text('Importieren'));
    await tester.pumpAndSettle();
    expect(settings.excludedTypeIds, {'glas'});
  });

  testWidgets('with sample data loaded the tile removes it again', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'biotonne', sourceId: 'sample'),
        PickupEvent(date: DateTime(2026, 1, 6), wasteTypeId: 'glas', sourceId: 'file:a'),
      ],
      wasteTypes: const [
        WasteType(id: 'biotonne', displayName: 'Biotonne', color: 1, icon: 'leaf'),
        WasteType(id: 'glas', displayName: 'Glas', color: 2, icon: 'bottle'),
      ],
    ));
    await pumpApp(tester, const Scaffold(body: DataSection()), overrides: testOverrides(events: repo));
    expect(find.text('Beispieldaten laden'), findsNothing);
    await tester.tap(find.text('Beispieldaten entfernen'));
    await tester.pumpAndSettle();
    expect(repo.data.events.map((e) => e.wasteTypeId), ['glas']);
    expect(repo.data.wasteTypes.map((t) => t.id), ['glas']);
    expect(find.text('Beispieldaten laden'), findsOneWidget);
  });

  testWidgets('delete all asks for confirmation and clears data', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'b', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'b', displayName: 'B', color: 1, icon: 'leaf')],
    ));
    final settings = InMemorySettingsRepository()..subscription = const Subscription(url: 'https://a.example/x.ics');
    final gateway = FakeNotificationGateway();
    await pumpApp(tester, const Scaffold(body: DataSection()),
        overrides: testOverrides(events: repo, settings: settings, gateway: gateway));
    await tester.tap(find.text('Alle Daten löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Wirklich alles löschen?'), findsOneWidget);
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(repo.data.events, isEmpty);
    expect(settings.subscription, isNull);
    expect(gateway.cancelAllCount, 1);
  });
}
