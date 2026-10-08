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
    await tester.tap(find.text('Zusammenführen'));
    await tester.pumpAndSettle();
    expect(repo.data.wasteTypes.map((t) => t.displayName), containsAll(['Restmüll', 'Biotonne', 'Papiertonne', 'Gelber Sack']));
    expect(repo.data.events.length, greaterThan(100));
    expect(repo.data.events.every((e) => e.sourceId == 'sample'), isTrue);
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
