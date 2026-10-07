import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../upcoming/providers/app_data_provider.dart';
import 'reminder_rules_provider.dart';

class ReminderSync {
  ReminderSync(this._ref);

  static const staleAfter = Duration(hours: 12);

  final Ref _ref;

  Future<void> rescheduleAll() async {
    final data = await _ref.read(appDataProvider.future);
    final rules = await _ref.read(reminderRulesProvider.future);
    await _ref.read(reminderCoordinatorProvider).reschedule(
          events: data.events,
          wasteTypes: data.wasteTypes,
          rules: rules,
        );
    await _ref.read(settingsRepositoryProvider).saveLastScheduleRun(_ref.read(clockProvider).now());
  }

  Future<void> rescheduleIfStale() async {
    final last = await _ref.read(settingsRepositoryProvider).loadLastScheduleRun();
    final now = _ref.read(clockProvider).now();
    if (last != null && now.difference(last) < staleAfter) return;
    await rescheduleAll();
  }
}

final reminderSyncProvider = Provider<ReminderSync>((ref) => ReminderSync(ref));
