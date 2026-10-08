import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_gateway.dart';
import '../domain/planned_notification.dart';
import '../domain/reminder_coordinator.dart';

class LocalNotificationsGateway implements NotificationGateway {
  LocalNotificationsGateway(this._prefs);

  final SharedPreferences _prefs;
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _requestedKey = 'notification_permission_requested';

  /// Einfarbiges Statusleisten-Icon, gerendert von test/tool/render_app_icon_test.dart
  /// nach android/app/src/main/res/drawable-*/ic_notification.png.
  static const androidSmallIcon = 'ic_notification';

  /// Akzentfarbe der App (NewakaColors.accent); hier als Konstante, weil
  /// diese Datei kein Flutter-Theme importieren soll.
  static const accentColor = Color(0xFF1B5E3A);

  static const _android = AndroidNotificationDetails(
    'abfuhr_erinnerungen',
    'Abfuhr-Erinnerungen',
    channelDescription: 'Erinnerungen an bevorstehende Abholungen',
    importance: Importance.high,
    priority: Priority.high,
    color: accentColor,
  );
  static const _details = NotificationDetails(
    android: _android,
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    await currentTimezone();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(androidSmallIcon),
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
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      await _prefs.setBool(_requestedKey, true);
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
      if (options.isEnabled) return NotificationPermission.granted;
      final requested = _prefs.getBool(_requestedKey) ?? false;
      return requested ? NotificationPermission.denied : NotificationPermission.unknown;
    }
    return NotificationPermission.unknown;
  }

  @override
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    return await _androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<void> requestExactAlarms() async {
    if (!Platform.isAndroid) return;
    await _androidPlugin?.requestExactAlarmsPermission();
  }

  /// Liest die Zeitzone bei jedem Aufruf neu, damit auch ein laufender Prozess
  /// nach einem Zeitzonenwechsel in der richtigen Zone plant.
  @override
  Future<String> currentTimezone() async {
    String zone;
    try {
      zone = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      zone = 'Europe/Berlin';
      tz.setLocalLocation(tz.getLocation(zone));
    }
    return zone;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(List<PlannedNotification> items) async {
    await currentTimezone();
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
