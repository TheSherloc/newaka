import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_gateway.dart';
import '../domain/planned_notification.dart';
import '../domain/reminder_coordinator.dart';

class LocalNotificationsGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _android = AndroidNotificationDetails(
    'abfuhr_erinnerungen',
    'Abfuhr-Erinnerungen',
    channelDescription: 'Erinnerungen an bevorstehende Abholungen',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(
    android: _android,
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _iosPlugin =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _androidPlugin;
      final granted = await android?.requestNotificationsPermission() ?? false;
      final exact = await android?.canScheduleExactNotifications() ?? true;
      if (!exact) await android?.requestExactAlarmsPermission();
      return granted;
    }
    if (Platform.isIOS) {
      return await _iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<NotificationPermission> permissionStatus() async {
    if (Platform.isAndroid) {
      final enabled = await _androidPlugin?.areNotificationsEnabled();
      if (enabled == null) return NotificationPermission.unknown;
      return enabled ? NotificationPermission.granted : NotificationPermission.denied;
    }
    if (Platform.isIOS) {
      final options = await _iosPlugin?.checkPermissions();
      if (options == null) return NotificationPermission.unknown;
      return options.isEnabled ? NotificationPermission.granted : NotificationPermission.denied;
    }
    return NotificationPermission.unknown;
  }

  @override
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    return await _androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(List<PlannedNotification> items) async {
    final exact = await canScheduleExact();
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final now = DateTime.now();
    for (final n in items) {
      if (!n.at.isAfter(now)) continue;
      try {
        await _plugin.zonedSchedule(
          id: n.id,
          scheduledDate: tz.TZDateTime.from(n.at, tz.local),
          notificationDetails: _details,
          androidScheduleMode: mode,
          title: n.title,
          body: n.body,
        );
      } catch (_) {
        continue;
      }
    }
  }

  @override
  Future<void> showNow({required String title, required String body}) =>
      _plugin.show(id: ReminderCoordinator.testNotificationId,title: title, body: body, notificationDetails: _details);
}
