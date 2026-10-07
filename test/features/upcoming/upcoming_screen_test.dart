import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/upcoming/ui/upcoming_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 0xFF6D4C41, icon: 'leaf');
PickupEvent ev(DateTime d) => PickupEvent(date: d, wasteTypeId: 'bio', sourceId: 's', note: 'Tonne bis 6:30 Uhr');

void main() {
  testWidgets('empty state offers import buttons', (tester) async {
    await pumpApp(tester, const UpcomingScreen(), overrides: testOverrides());
    expect(find.text('Noch keine Termine'), findsOneWidget);
    expect(find.text('Datei importieren'), findsOneWidget);
    expect(find.text('URL eintragen'), findsOneWidget);
  });

  testWidgets('shows next pickup hero and list', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [ev(DateTime(2026, 1, 2)), ev(DateTime(2026, 1, 9))],
      wasteTypes: const [bio],
    ));
    await pumpApp(tester, const UpcomingScreen(),
        overrides: testOverrides(events: repo, clock: FixedClock(DateTime(2026, 1, 1, 12))));
    expect(find.text('Nächste Abholung'), findsOneWidget);
    expect(find.text('Morgen'), findsWidgets);
    expect(find.text('Biotonne'), findsWidgets);
    expect(find.textContaining('6:30'), findsOneWidget);
    expect(find.text('in 8 Tagen'), findsOneWidget);
  });

  testWidgets('only past events shows no-upcoming state, not onboarding', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [ev(DateTime(2025, 6, 1))],
      wasteTypes: const [bio],
    ));
    await pumpApp(tester, const UpcomingScreen(),
        overrides: testOverrides(events: repo, clock: FixedClock(DateTime(2026, 1, 1))));
    expect(find.text('Keine anstehenden Termine'), findsOneWidget);
    expect(find.text('Noch keine Termine'), findsNothing);
  });
}
