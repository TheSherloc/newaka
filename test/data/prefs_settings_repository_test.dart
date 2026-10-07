import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/repositories/prefs_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rules: null when never saved, roundtrip after save', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    expect(await repo.loadRules(), isNull);
    await repo.saveRules(ReminderRule.defaults());
    final rules = await repo.loadRules();
    expect(rules!.length, 2);
    expect(rules[0].id, 'default-evening');
  });

  test('subscription roundtrip and clearing', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    expect(await repo.loadSubscription(), isNull);
    await repo.saveSubscription(const Subscription(url: 'https://a.de/x.ics'));
    expect((await repo.loadSubscription())!.url, 'https://a.de/x.ics');
    await repo.saveSubscription(null);
    expect(await repo.loadSubscription(), isNull);
  });

  test('last schedule run roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    expect(await repo.loadLastScheduleRun(), isNull);
    await repo.saveLastScheduleRun(DateTime(2026, 1, 1, 8));
    expect(await repo.loadLastScheduleRun(), DateTime(2026, 1, 1, 8));
  });
}
