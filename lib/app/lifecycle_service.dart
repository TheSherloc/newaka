import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/import/providers/subscription_provider.dart';
import '../features/reminders/providers/reminder_sync.dart';
import '../features/upcoming/providers/app_data_provider.dart';

class LifecycleService {
  LifecycleService(this._ref);
  final Ref _ref;

  /// Automatic refresh must never surface errors to the user, so each step
  /// swallows its own failures.
  Future<void> onStart() async {
    try {
      await _ref.read(appDataProvider.future);
    } catch (_) {}
    try {
      await _ref.read(subscriptionProvider.notifier).refresh();
    } catch (_) {}
    try {
      await _ref.read(reminderSyncProvider).rescheduleIfStale();
    } catch (_) {}
  }

  Future<void> onResumed() => onStart();
}

final lifecycleServiceProvider = Provider<LifecycleService>((ref) => LifecycleService(ref));
