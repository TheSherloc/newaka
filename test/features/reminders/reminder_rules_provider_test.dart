import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/reminders/providers/reminder_rules_provider.dart';
import 'package:abfallkalender/features/reminders/providers/reminder_sync.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/test_container.dart';

final seeded = AppData(
  events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'bio', sourceId: 's')],
  wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
);

void main() {
  test('defaults when nothing saved', () async {
    final c = createTestContainer();
    final rules = await c.read(reminderRulesProvider.future);
    expect(rules.length, 2);
  });

  test('loads saved rules', () async {
    final settings = InMemorySettingsRepository()
      ..rules = [const ReminderRule(id: 'r1', daysBefore: 2, hour: 9, minute: 15)];
    final c = createTestContainer(settings: settings);
    final rules = await c.read(reminderRulesProvider.future);
    expect(rules.single.id, 'r1');
  });

  test('add, update, remove persist and reschedule; add respects max', () async {
    final settings = InMemorySettingsRepository();
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(
      settings: settings, gateway: gateway, events: InMemoryEventRepository(seeded),
    );
    final notifier = c.read(reminderRulesProvider.notifier);
    await c.read(reminderRulesProvider.future);

    await notifier.add(const ReminderRule(id: 'n1', daysBefore: 2, hour: 9, minute: 0));
    expect(settings.rules!.length, 3);
    expect(gateway.scheduled.length, 3);

    await notifier.updateRule(const ReminderRule(id: 'n1', daysBefore: 2, hour: 9, minute: 0, enabled: false));
    expect(gateway.scheduled.length, 2);

    await notifier.remove('n1');
    expect(settings.rules!.length, 2);

    for (var i = 0; i < 5; i++) {
      await notifier.add(ReminderRule(id: 'x$i', daysBefore: 1, hour: 8 + i, minute: 0));
    }
    expect(settings.rules!.length, ReminderRule.maxRules);
  });

  test('rescheduleIfStale only runs after 12 hours', () async {
    final settings = InMemorySettingsRepository()..lastScheduleRun = DateTime(2026, 1, 1, 6);
    final gateway = FakeNotificationGateway();
    final c = createTestContainer(settings: settings, gateway: gateway, events: InMemoryEventRepository(seeded));
    await c.read(reminderSyncProvider).rescheduleIfStale(); // now = 12:00, 6h alt
    expect(gateway.cancelAllCount, 0);
    settings.lastScheduleRun = DateTime(2025, 12, 31, 6);
    await c.read(reminderSyncProvider).rescheduleIfStale();
    expect(gateway.cancelAllCount, 1);
    expect(settings.lastScheduleRun, DateTime(2026, 1, 1, 12));
  });

  test('iOS uses 60 limit with hint, android 200 without', () async {
    final many = AppData(
      events: [for (var d = 1; d <= 100; d++) PickupEvent(date: DateTime(2026, 1, 1).add(Duration(days: d)), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: seeded.wasteTypes,
    );
    final ios = FakeNotificationGateway();
    final cIos = createTestContainer(gateway: ios, events: InMemoryEventRepository(many), isIos: true);
    await cIos.read(reminderSyncProvider).rescheduleAll();
    expect(ios.scheduled.length, 61);

    final android = FakeNotificationGateway();
    final cAndroid = createTestContainer(gateway: android, events: InMemoryEventRepository(many));
    await cAndroid.read(reminderSyncProvider).rescheduleAll();
    expect(android.scheduled.length, 200);
  });

  test('add before load completes keeps saved rules', () async {
    final settings = InMemorySettingsRepository()
      ..rules = [const ReminderRule(id: 'saved', daysBefore: 2, hour: 9, minute: 0)];
    final c = createTestContainer(settings: settings, events: InMemoryEventRepository(seeded));
    await c.read(reminderRulesProvider.notifier).add(const ReminderRule(id: 'n1', daysBefore: 0, hour: 8, minute: 0));
    expect(settings.rules!.map((r) => r.id), ['saved', 'n1']);
  });
}
