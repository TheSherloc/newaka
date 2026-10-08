import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/waste_types/ui/waste_types_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:abfallkalender/data/models/pickup_event.dart';

import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 0xFF6D4C41, icon: 'leaf');

void main() {
  testWidgets('lists types, toggles visibility, edits name and color', (tester) async {
    final repo = InMemoryEventRepository(const AppData(events: [], wasteTypes: [bio]));
    await pumpApp(tester, const Scaffold(body: SingleChildScrollView(child: WasteTypesSection())),
        overrides: testOverrides(events: repo));

    expect(find.text('Biotonne'), findsOneWidget);
    expect(find.text('Aktiv'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.data.wasteTypes.single.enabled, isFalse);
    expect(find.text('Ausgeblendet'), findsOneWidget);

    await tester.tap(find.text('Biotonne'));
    await tester.pumpAndSettle();
    expect(find.text('Abfuhrart bearbeiten'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bio');
    await tester.tap(find.byKey(const Key('color-0xFF1E88E5')));
    await tester.tap(find.byKey(const Key('icon-paper')));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final saved = repo.data.wasteTypes.single;
    expect(saved.displayName, 'Bio');
    expect(saved.color, 0xFF1E88E5);
    expect(saved.icon, 'paper');
    expect(saved.id, 'bio');
  });

  testWidgets('deleting a type asks with the event count and removes it', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's'),
        PickupEvent(date: DateTime(2026, 1, 19), wasteTypeId: 'bio', sourceId: 's'),
      ],
      wasteTypes: const [bio],
    ));
    final settings = InMemorySettingsRepository();
    await pumpApp(tester, const Scaffold(body: SingleChildScrollView(child: WasteTypesSection())),
        overrides: testOverrides(events: repo, settings: settings));

    await tester.tap(find.text('Biotonne'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abfuhrart löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Biotonne löschen?'), findsOneWidget);
    expect(find.textContaining('2 Termine'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repo.data.wasteTypes, hasLength(1));

    await tester.tap(find.text('Biotonne'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abfuhrart löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(repo.data.wasteTypes, isEmpty);
    expect(repo.data.events, isEmpty);
    expect(settings.excludedTypeIds, {'bio'});
    expect(find.text('Biotonne'), findsNothing);
  });
}
