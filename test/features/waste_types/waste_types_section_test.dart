import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/waste_types/ui/waste_types_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 0xFF6D4C41, icon: 'leaf');

void main() {
  testWidgets('lists types, toggles notifications, edits name and color', (tester) async {
    final repo = InMemoryEventRepository(const AppData(events: [], wasteTypes: [bio]));
    await pumpApp(tester, const Scaffold(body: SingleChildScrollView(child: WasteTypesSection())),
        overrides: testOverrides(events: repo));

    expect(find.text('Biotonne'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.data.wasteTypes.single.notificationsEnabled, isFalse);

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
}
