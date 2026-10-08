import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/upcoming/domain/upcoming_groups.dart';
import 'package:flutter_test/flutter_test.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
const papier = WasteType(id: 'papier', displayName: 'Altpapier', color: 2, icon: 'paper');
PickupEvent ev(DateTime d, String t, {String? note}) =>
    PickupEvent(date: d, wasteTypeId: t, sourceId: 's', note: note);

void main() {
  test('groups by day within horizon, sorted, includes today, excludes past', () {
    final data = AppData(
      events: [
        ev(DateTime(2025, 12, 31), 'bio'),
        ev(DateTime(2026, 1, 1), 'bio', note: 'bis 6:30'),
        ev(DateTime(2026, 1, 5), 'papier'),
        ev(DateTime(2026, 1, 5), 'bio'),
        ev(DateTime(2026, 3, 1), 'bio'),
      ],
      wasteTypes: const [bio, papier],
    );
    final groups = upcomingGroups(data: data, now: DateTime(2026, 1, 1, 15));
    expect(groups.length, 2);
    expect(groups[0].date, DateTime(2026, 1, 1));
    expect(groups[0].note, 'bis 6:30');
    expect(groups[1].types.map((t) => t.id), ['papier', 'bio']);
  });

  test('hides events of disabled waste types', () {
    const rest = WasteType(id: 'rest', displayName: 'Rest', color: 3, icon: 'trash', enabled: false);
    final data = AppData(
      events: [ev(DateTime(2026, 1, 2), 'rest'), ev(DateTime(2026, 1, 3), 'bio')],
      wasteTypes: const [bio, rest],
    );
    final groups = upcomingGroups(data: data, now: DateTime(2026, 1, 1));
    expect(groups.map((g) => g.date), [DateTime(2026, 1, 3)]);
  });

  test('ignores events with unknown waste type', () {
    final data = AppData(events: [ev(DateTime(2026, 1, 2), 'x')], wasteTypes: const [bio]);
    expect(upcomingGroups(data: data, now: DateTime(2026, 1, 1)), isEmpty);
  });
}
