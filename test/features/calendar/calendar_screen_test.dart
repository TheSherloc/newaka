import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/calendar/ui/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 0xFF6D4C41, icon: 'leaf');

void main() {
  testWidgets('shows calendar, legend, markers and day details on tap', (tester) async {
    final repo = InMemoryEventRepository(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 15), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: const [bio],
    ));
    await pumpApp(tester, const CalendarScreen(),
        overrides: testOverrides(events: repo, clock: FixedClock(DateTime(2026, 1, 10))));

    expect(find.byType(TableCalendar<WasteType>), findsOneWidget);
    expect(find.text('Legende'), findsOneWidget);
    expect(find.byKey(const Key('marker-2026-01-15-bio')), findsOneWidget);
    expect(find.text('Keine Abholung an diesem Tag'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('Keine Abholung an diesem Tag'), findsNothing);
    expect(find.text('Biotonne'), findsWidgets);
  });

  testWidgets('Heute button exists', (tester) async {
    await pumpApp(tester, const CalendarScreen(), overrides: testOverrides());
    expect(find.byTooltip('Heute'), findsOneWidget);
  });
}
