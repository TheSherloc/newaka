import 'planned_notification.dart';

enum NotificationPermission { granted, denied, unknown }

abstract class NotificationGateway {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<NotificationPermission> permissionStatus();
  Future<bool> canScheduleExact();
  Future<void> cancelAll();
  Future<void> schedule(List<PlannedNotification> items);
  Future<void> showNow({required String title, required String body});
}
