import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_rule.dart';
import '../models/subscription.dart';
import 'settings_repository.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _rulesKey = 'reminder_rules';
  static const _subscriptionKey = 'subscription';
  static const _lastRunKey = 'last_schedule_run';
  static const _excludedTypesKey = 'excluded_type_ids';

  @override
  Future<List<ReminderRule>?> loadRules() async {
    final raw = _prefs.getString(_rulesKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => ReminderRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveRules(List<ReminderRule> rules) =>
      _prefs.setString(_rulesKey, jsonEncode(rules.map((r) => r.toJson()).toList()));

  @override
  Future<Subscription?> loadSubscription() async {
    final raw = _prefs.getString(_subscriptionKey);
    if (raw == null) return null;
    return Subscription.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveSubscription(Subscription? subscription) async {
    if (subscription == null) {
      await _prefs.remove(_subscriptionKey);
    } else {
      await _prefs.setString(_subscriptionKey, jsonEncode(subscription.toJson()));
    }
  }

  @override
  Future<DateTime?> loadLastScheduleRun() async {
    final raw = _prefs.getString(_lastRunKey);
    return raw == null ? null : DateTime.parse(raw);
  }

  @override
  Future<void> saveLastScheduleRun(DateTime when) =>
      _prefs.setString(_lastRunKey, when.toIso8601String());

  @override
  Future<Set<String>> loadExcludedTypeIds() async =>
      (_prefs.getStringList(_excludedTypesKey) ?? const []).toSet();

  @override
  Future<void> saveExcludedTypeIds(Set<String> ids) =>
      _prefs.setStringList(_excludedTypesKey, ids.toList()..sort());
}
