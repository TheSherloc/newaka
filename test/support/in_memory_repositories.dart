import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/reminder_rule.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/repositories/event_repository.dart';
import 'package:abfallkalender/data/repositories/settings_repository.dart';

class InMemoryEventRepository implements EventRepository {
  InMemoryEventRepository([this.data = AppData.empty]);

  AppData data;
  bool corruptOnLoad = false;
  int saveCount = 0;

  @override
  Future<LoadResult> load() async {
    final corrupt = corruptOnLoad;
    corruptOnLoad = false;
    return LoadResult(data: corrupt ? AppData.empty : data, wasCorrupt: corrupt);
  }

  @override
  Future<void> save(AppData data) async {
    this.data = data;
    saveCount++;
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  List<ReminderRule>? rules;
  Subscription? subscription;
  DateTime? lastScheduleRun;

  @override
  Future<List<ReminderRule>?> loadRules() async => rules;
  @override
  Future<void> saveRules(List<ReminderRule> rules) async => this.rules = rules;
  @override
  Future<Subscription?> loadSubscription() async => subscription;
  @override
  Future<void> saveSubscription(Subscription? subscription) async =>
      this.subscription = subscription;
  @override
  Future<DateTime?> loadLastScheduleRun() async => lastScheduleRun;
  @override
  Future<void> saveLastScheduleRun(DateTime when) async => lastScheduleRun = when;
}
