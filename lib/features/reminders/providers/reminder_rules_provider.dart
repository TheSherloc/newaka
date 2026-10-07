import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../data/models/reminder_rule.dart';
import 'reminder_sync.dart';

class ReminderRulesNotifier extends AsyncNotifier<List<ReminderRule>> {
  @override
  Future<List<ReminderRule>> build() async {
    final saved = await ref.read(settingsRepositoryProvider).loadRules();
    return saved ?? ReminderRule.defaults();
  }

  List<ReminderRule> get _current => state.value ?? ReminderRule.defaults();

  Future<void> _commit(List<ReminderRule> rules) async {
    await ref.read(settingsRepositoryProvider).saveRules(rules);
    state = AsyncData(rules);
    await ref.read(reminderSyncProvider).rescheduleAll();
  }

  Future<void> add(ReminderRule rule) async {
    if (_current.length >= ReminderRule.maxRules) return;
    await _commit([..._current, rule]);
  }

  Future<void> updateRule(ReminderRule rule) =>
      _commit(_current.map((r) => r.id == rule.id ? rule : r).toList());

  Future<void> remove(String id) => _commit(_current.where((r) => r.id != id).toList());
}

final reminderRulesProvider =
    AsyncNotifierProvider<ReminderRulesNotifier, List<ReminderRule>>(ReminderRulesNotifier.new);
