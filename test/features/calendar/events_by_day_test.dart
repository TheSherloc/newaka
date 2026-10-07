import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/calendar/domain/events_by_day.dart';
import 'package:flutter_test/flutter_test.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
const papier = WasteType(id: 'papier', displayName: 'Altpapier', color: 2, icon: 'paper');

void main() {
  test('maps iso date to sorted unique types, ignoring unknown', () {
    final data = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'papier', sourceId: 's'),
        PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's'),
        PickupEvent(date: DateTime(2026, 1, 6), wasteTypeId: 'unknown', sourceId: 's'),
      ],
      wasteTypes: const [bio, papier],
    );
    final m = eventsByDay(data);
    expect(m.keys, ['2026-01-05']);
    expect(m['2026-01-05']!.map((t) => t.id), ['papier', 'bio']);
  });
}
