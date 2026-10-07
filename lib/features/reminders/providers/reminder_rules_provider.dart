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

  Future<void> _commit(List<ReminderRule> rules) async {
    await ref.read(settingsRepositoryProvider).saveRules(rules);
    state = AsyncData(rules);
    await ref.read(reminderSyncProvider).rescheduleAll();
  }

  Future<void> add(ReminderRule rule) async {
    final current = await future;
    if (current.length >= ReminderRule.maxRules) return;
    await _commit([...current, rule]);
  }

  Future<void> updateRule(ReminderRule rule) async {
    final current = await future;
    await _commit(current.map((r) => r.id == rule.id ? rule : r).toList());
  }

  Future<void> remove(String id) async {
    final current = await future;
    await _commit(current.where((r) => r.id != id).toList());
  }
}

final reminderRulesProvider =
    AsyncNotifierProvider<ReminderRulesNotifier, List<ReminderRule>>(ReminderRulesNotifier.new);
