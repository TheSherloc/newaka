import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
const papier = WasteType(id: 'papier', displayName: 'Altpapier Tonne', color: 2, icon: 'paper');
const rest = WasteType(id: 'rest', displayName: 'Restmüll', color: 3, icon: 'trash', enabled: false);

PickupEvent ev(DateTime d, String type) => PickupEvent(date: d, wasteTypeId: type, sourceId: 's');

void main() {
  final scheduler = ReminderScheduler();
  final rules = ReminderRule.defaults(); // Vortag 18:00, Abholtag 07:00
  final now = DateTime(2026, 1, 1, 12);

  test('plans one notification per day and rule, in time order', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 1, 5), 'bio')],
      wasteTypes: const [bio],
      rules: rules,
      now: now,
      limit: 100,
    );
    expect(out.length, 2);
    expect(out[0].at, DateTime(2026, 1, 4, 18, 0));
    expect(out[0].title, 'Morgen Abholung');
    expect(out[0].body, 'Biotonne');
    expect(out[1].at, DateTime(2026, 1, 5, 7, 0));
    expect(out[1].title, 'Heute Abholung');
  });

  test('combines multiple types on one day into one notification', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 1, 5), 'papier'), ev(DateTime(2026, 1, 5), 'bio')],
      wasteTypes: const [bio, papier],
      rules: [rules[0]],
      now: now,
      limit: 100,
    );
    expect(out.single.body, 'Altpapier Tonne und Biotonne');
  });

  test('joinNames for three uses comma and und', () {
    expect(ReminderScheduler.joinNames(['A', 'B', 'C']), 'A, B und C');
    expect(ReminderScheduler.joinNames(['A']), 'A');
  });

  test('skips muted types, disabled rules and past times', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 1, 1), 'bio'), ev(DateTime(2026, 1, 5), 'rest')],
      wasteTypes: const [bio, rest],
      rules: [rules[0], rules[1].copyWith(enabled: false)],
      now: now,
      limit: 100,
    );
    expect(out, isEmpty);
  });

  test('respects limit and keeps earliest', () {
    final events = [for (var d = 2; d <= 30; d++) ev(DateTime(2026, 1, d), 'bio')];
    final out = scheduler.plan(
      events: events, wasteTypes: const [bio], rules: rules, now: now, limit: 5,
    );
    expect(out.length, 5);
    expect(out.first.at, DateTime(2026, 1, 1, 18));
  });

  test('titles for daysBefore', () {
    expect(ReminderScheduler.titleFor(0), 'Heute Abholung');
    expect(ReminderScheduler.titleFor(1), 'Morgen Abholung');
    expect(ReminderScheduler.titleFor(2), 'Übermorgen Abholung');
  });

  test('ids are deterministic, distinct per rule time, and positive 31-bit', () {
    final a = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 1, 18, 0);
    final b = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 1, 18, 0);
    final c = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 1, 19, 0);
    final d = ReminderScheduler.notificationId(DateTime(2026, 1, 5), 0, 18, 0);
    expect(a, b);
    expect(a, isNot(c));
    expect(a, isNot(d));
    expect(a, greaterThan(1));
    expect(a, lessThan(1 << 31));
  });

  test('rule time on DST switch day yields a valid future time', () {
    final out = scheduler.plan(
      events: [ev(DateTime(2026, 3, 30), 'bio')],
      wasteTypes: const [bio],
      rules: const [ReminderRule(id: 'x', daysBefore: 1, hour: 2, minute: 30)],
      now: DateTime(2026, 3, 1),
      limit: 10,
    );
    expect(out.single.at.year, 2026);
    expect(out.single.at.month, 3);
    expect(out.single.at.day, 29);
  });
}
