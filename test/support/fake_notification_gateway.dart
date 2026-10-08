import 'package:abfallkalender/features/reminders/domain/notification_gateway.dart';
import 'package:abfallkalender/features/reminders/domain/planned_notification.dart';

class FakeNotificationGateway implements NotificationGateway {
  final List<PlannedNotification> scheduled = [];
  final List<(String, String)> shown = [];
  int cancelAllCount = 0;
  int requestCount = 0;
  int exactRequestCount = 0;
  NotificationPermission permission = NotificationPermission.unknown;
  bool exactAllowed = true;
  bool grantOnRequest = true;
  String timezone = 'Europe/Berlin';

  @override
  Future<void> initialize() async {}

  @override
  Future<String> currentTimezone() async => timezone;

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    permission = grantOnRequest ? NotificationPermission.granted : NotificationPermission.denied;
    return grantOnRequest;
  }

  @override
  Future<NotificationPermission> permissionStatus() async => permission;

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<void> requestExactAlarms() async {
    exactRequestCount++;
    exactAllowed = true;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(List<PlannedNotification> items) async => scheduled.addAll(items);

  @override
  Future<void> showNow({required String title, required String body}) async =>
      shown.add((title, body));
}
