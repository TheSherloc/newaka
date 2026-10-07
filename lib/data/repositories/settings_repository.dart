import '../models/reminder_rule.dart';
import '../models/subscription.dart';

abstract class SettingsRepository {
  /// `null` bedeutet: noch nie gespeichert (Aufrufer nutzt Standardregeln).
  Future<List<ReminderRule>?> loadRules();
  Future<void> saveRules(List<ReminderRule> rules);

  Future<Subscription?> loadSubscription();
  Future<void> saveSubscription(Subscription? subscription);

  Future<DateTime?> loadLastScheduleRun();
  Future<void> saveLastScheduleRun(DateTime when);
}
