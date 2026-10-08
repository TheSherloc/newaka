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
    final settings = _ref.read(settingsRepositoryProvider);
    await settings.saveLastScheduleRun(_ref.read(clockProvider).now());
    await settings.saveLastScheduleTimezone(await _ref.read(notificationGatewayProvider).currentTimezone());
  }

  /// Plant neu, wenn die letzte Planung zu alt ist oder in einer anderen
  /// Zeitzone stattfand. Alarme sind feste Zeitpunkte: Nach einem Wechsel von
  /// GMT nach Berlin käme "18:00" sonst um 20:00.
  Future<void> rescheduleIfStale() async {
    final settings = _ref.read(settingsRepositoryProvider);
    final last = await settings.loadLastScheduleRun();
    final now = _ref.read(clockProvider).now();
    final fresh = last != null && now.difference(last) < staleAfter;
    final zone = await _ref.read(notificationGatewayProvider).currentTimezone();
    final sameZone = await settings.loadLastScheduleTimezone() == zone;
    if (fresh && sameZone) return;
    await rescheduleAll();
  }
}

final reminderSyncProvider = Provider<ReminderSync>((ref) => ReminderSync(ref));
