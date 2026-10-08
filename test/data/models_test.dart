import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PickupEvent key and json roundtrip', () {
    final e = PickupEvent(
      date: DateTime(2026, 1, 2),
      wasteTypeId: 'biotonne',
      sourceId: 'file:a.csv',
      note: 'bis 6:30',
    );
    expect(e.key, '2026-01-02|biotonne');
    final back = PickupEvent.fromJson(e.toJson());
    expect(back.date, DateTime(2026, 1, 2));
    expect(back.wasteTypeId, 'biotonne');
    expect(back.sourceId, 'file:a.csv');
    expect(back.note, 'bis 6:30');
    expect(back, equals(e));
  });

  test('WasteType json roundtrip and copyWith', () {
    const t = WasteType(
      id: 'biotonne',
      displayName: 'Biotonne',
      color: 0xFF6D4C41,
      icon: 'leaf',
      enabled: true,
    );
    final back = WasteType.fromJson(t.toJson());
    expect(back.id, 'biotonne');
    expect(back.color, 0xFF6D4C41);
    expect(t.copyWith(enabled: false).enabled, false);
    expect(WasteType.fromJson(t.copyWith(enabled: false).toJson()).enabled, isFalse);
    expect(t.copyWith(displayName: 'Bio').id, 'biotonne');
  });

  test('WasteType reads the legacy notificationsEnabled key', () {
    final json = {'id': 'bio', 'displayName': 'Bio', 'color': 1, 'icon': 'leaf', 'notificationsEnabled': false};
    expect(WasteType.fromJson(json).enabled, isFalse);
    expect(WasteType.fromJson({...json}..remove('notificationsEnabled')).enabled, isTrue);
  });

  test('AppData.activeWasteTypes leaves out disabled types', () {
    const data = AppData(events: [], wasteTypes: [
      WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf'),
      WasteType(id: 'rest', displayName: 'Rest', color: 2, icon: 'trash', enabled: false),
    ]);
    expect(data.activeWasteTypes.map((t) => t.id), ['bio']);
  });

  test('ReminderRule defaults and json', () {
    final d = ReminderRule.defaults();
    expect(d.length, 2);
    expect(d[0].daysBefore, 1);
    expect(d[0].hour, 18);
    expect(d[0].minute, 0);
    expect(d[1].daysBefore, 0);
    expect(d[1].hour, 7);
    expect(d.every((r) => r.enabled), isTrue);
    final back = ReminderRule.fromJson(d[0].toJson());
    expect(back.id, d[0].id);
    expect(ReminderRule.maxRules, 5);
  });

  test('Subscription json roundtrip with nulls', () {
    const s = Subscription(url: 'https://x.de/a.ics');
    final back = Subscription.fromJson(s.toJson());
    expect(back.url, 'https://x.de/a.ics');
    expect(back.lastFetched, isNull);
    expect(back.lastError, isNull);
    final s2 = s.copyWith(lastFetched: DateTime(2026, 1, 1, 10), lastError: 'x');
    final back2 = Subscription.fromJson(s2.toJson());
    expect(back2.lastFetched, DateTime(2026, 1, 1, 10));
    expect(back2.lastError, 'x');
    expect(s2.copyWith(clearError: true).lastError, isNull);
  });

  test('AppData json roundtrip includes schemaVersion', () {
    final data = AppData(
      events: [
        PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'biotonne', sourceId: 's'),
      ],
      wasteTypes: const [
        WasteType(id: 'biotonne', displayName: 'Biotonne', color: 1, icon: 'leaf'),
      ],
    );
    final json = data.toJson();
    expect(json['schemaVersion'], AppData.schemaVersion);
    final back = AppData.fromJson(json);
    expect(back.events.length, 1);
    expect(back.wasteTypes.single.id, 'biotonne');
    expect(AppData.empty.events, isEmpty);
  });
}
