import '../../../core/clock.dart';
import '../../../data/models/pickup_event.dart';
import '../../../data/models/reminder_rule.dart';
import '../../../data/models/waste_type.dart';
import 'notification_gateway.dart';
import 'planned_notification.dart';
import 'reminder_scheduler.dart';

class ReminderCoordinator {
  ReminderCoordinator({
    required this.gateway,
    required this.scheduler,
    required this.clock,
    required this.maxPending,
    required this.addRefreshHint,
  });

  static const refreshHintId = 1;
  static const testNotificationId = 2;
  static const iosMaxPending = 60;
  static const androidMaxPending = 200;
  static const refreshHintTitle = 'Abfallkalender';
  static const refreshHintBody =
      'Bitte die App öffnen, damit die Erinnerungen aktuell bleiben.';

  final NotificationGateway gateway;
  final ReminderScheduler scheduler;
  final Clock clock;
  final int maxPending;
  final bool addRefreshHint;

  /// Plant das rollierende Fenster neu. Gibt die Anzahl geplanter Erinnerungen zurück.
  Future<int> reschedule({
    required List<PickupEvent> events,
    required List<WasteType> wasteTypes,
    required List<ReminderRule> rules,
  }) async {
    final planned = scheduler.plan(
      events: events,
      wasteTypes: wasteTypes,
      rules: rules,
      now: clock.now(),
      limit: maxPending + 1,
    );
    final truncated = planned.length > maxPending;
    final window = truncated ? planned.sublist(0, maxPending) : planned;

    await gateway.cancelAll();
    final toSchedule = [...window];
    if (addRefreshHint && truncated) {
      toSchedule.add(PlannedNotification(
        id: refreshHintId,
        at: window.last.at.add(const Duration(days: 1)),
        title: refreshHintTitle,
        body: refreshHintBody,
      ));
    }
    await gateway.schedule(toSchedule);
    return window.length;
  }
}
