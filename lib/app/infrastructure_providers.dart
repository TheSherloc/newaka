import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../features/import/domain/import_service.dart';
import '../features/reminders/domain/notification_gateway.dart';
import '../features/reminders/domain/reminder_coordinator.dart';
import '../features/reminders/domain/reminder_scheduler.dart';

final clockProvider = Provider<Clock>((_) => const SystemClock());

final eventRepositoryProvider = Provider<EventRepository>(
  (_) => throw UnimplementedError('eventRepositoryProvider muss in main überschrieben werden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (_) => throw UnimplementedError('settingsRepositoryProvider muss in main überschrieben werden'),
);

final notificationGatewayProvider = Provider<NotificationGateway>(
  (_) => throw UnimplementedError('notificationGatewayProvider muss in main überschrieben werden'),
);

final isIosProvider = Provider<bool>((_) => Platform.isIOS);

final importServiceProvider = Provider<ImportService>((_) => ImportService());

final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  final isIos = ref.watch(isIosProvider);
  return ReminderCoordinator(
    gateway: ref.watch(notificationGatewayProvider),
    scheduler: ReminderScheduler(),
    clock: ref.watch(clockProvider),
    maxPending: isIos ? ReminderCoordinator.iosMaxPending : ReminderCoordinator.androidMaxPending,
    addRefreshHint: isIos,
  );
});
