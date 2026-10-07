import '../../../core/dates.dart';
import '../../../data/models/pickup_event.dart';
import '../../../data/models/reminder_rule.dart';
import '../../../data/models/waste_type.dart';
import 'planned_notification.dart';

class ReminderScheduler {
  static const titleToday = 'Heute Abholung';
  static const titleTomorrow = 'Morgen Abholung';
  static const titleDayAfter = 'Übermorgen Abholung';

  static String titleFor(int daysBefore) => switch (daysBefore) {
        0 => titleToday,
        1 => titleTomorrow,
        2 => titleDayAfter,
        _ => 'Abholung in $daysBefore Tagen',
      };

  static String joinNames(List<String> names) {
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} und ${names.last}';
  }

  /// Deterministische ID: Tage seit 2000-01-01 (16 Bit) * 16384 + Slot (14 Bit) + 1000.
  /// IDs unter 1000 bleiben für feste Benachrichtigungen (Test, Hinweis) frei.
  static int notificationId(DateTime date, int daysBefore, int hour, int minute) {
    final days = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2000, 1, 1))
        .inDays;
    final slot = daysBefore * 1440 + hour * 60 + minute;
    return days * 16384 + slot + 1000;
  }

  List<PlannedNotification> plan({
    required List<PickupEvent> events,
    required List<WasteType> wasteTypes,
    required List<ReminderRule> rules,
    required DateTime now,
    required int limit,
  }) {
    final typeById = {for (final t in wasteTypes) t.id: t};
    final namesByDate = <String, Set<String>>{};
    for (final e in events) {
      final type = typeById[e.wasteTypeId];
      if (type == null || !type.notificationsEnabled) continue;
      namesByDate.putIfAbsent(e.date.isoDate, () => <String>{}).add(type.displayName);
    }

    final out = <PlannedNotification>[];
    for (final entry in namesByDate.entries) {
      final date = parseIsoDate(entry.key)!;
      final names = entry.value.toList()..sort();
      for (final rule in rules.where((r) => r.enabled)) {
        final at = DateTime(
          date.year, date.month, date.day - rule.daysBefore, rule.hour, rule.minute,
        );
        if (!at.isAfter(now)) continue;
        out.add(PlannedNotification(
          id: notificationId(date, rule.daysBefore, rule.hour, rule.minute),
          at: at,
          title: titleFor(rule.daysBefore),
          body: joinNames(names),
        ));
      }
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out.length > limit ? out.sublist(0, limit) : out;
  }
}
