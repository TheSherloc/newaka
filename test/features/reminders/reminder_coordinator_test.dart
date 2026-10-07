import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/reminders/domain/reminder_coordinator.dart';
import 'package:abfallkalender/features/reminders/domain/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';

const bio = WasteType(id: 'bio', displayName: 'Biotonne', color: 1, icon: 'leaf');
PickupEvent ev(int day) =>
    PickupEvent(date: DateTime(2026, 1, day), wasteTypeId: 'bio', sourceId: 's');

void main() {
  final rules = ReminderRule.defaults();
  final clock = FixedClock(DateTime(2026, 1, 1));

  test('cancels all, schedules window, no hint when everything fits', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 60, addRefreshHint: true,
    );
    final n = await c.reschedule(events: [ev(5), ev(12)], wasteTypes: const [bio], rules: rules);
    expect(n, 4);
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled.length, 4);
    expect(gateway.scheduled.any((p) => p.id == ReminderCoordinator.refreshHintId), isFalse);
  });

  test('adds refresh hint one day after last planned when truncated (iOS)', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 4, addRefreshHint: true,
    );
    final events = [for (var d = 2; d <= 20; d++) ev(d)];
    final n = await c.reschedule(events: events, wasteTypes: const [bio], rules: rules);
    expect(n, 4);
    expect(gateway.scheduled.length, 5);
    final hint = gateway.scheduled.last;
    expect(hint.id, ReminderCoordinator.refreshHintId);
    final lastReminder = gateway.scheduled[3].at;
    expect(hint.at, lastReminder.add(const Duration(days: 1)));
    expect(hint.body, contains('öffnen'));
  });

  test('no hint on android even when truncated', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 4, addRefreshHint: false,
    );
    final events = [for (var d = 2; d <= 20; d++) ev(d)];
    await c.reschedule(events: events, wasteTypes: const [bio], rules: rules);
    expect(gateway.scheduled.length, 4);
  });

  test('empty data cancels and schedules nothing', () async {
    final gateway = FakeNotificationGateway();
    final c = ReminderCoordinator(
      gateway: gateway, scheduler: ReminderScheduler(), clock: clock,
      maxPending: 60, addRefreshHint: true,
    );
    final n = await c.reschedule(events: const [], wasteTypes: const [], rules: rules);
    expect(n, 0);
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled, isEmpty);
  });
}
