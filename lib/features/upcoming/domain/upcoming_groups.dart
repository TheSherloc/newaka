import '../../../core/dates.dart';
import '../../../data/models/app_data.dart';
import '../../../data/models/waste_type.dart';

class DayGroup {
  const DayGroup({required this.date, required this.types, this.note});
  final DateTime date;
  final List<WasteType> types;
  final String? note;
}

List<DayGroup> upcomingGroups({
  required AppData data,
  required DateTime now,
  int horizonDays = 28,
}) {
  final typeById = {for (final t in data.activeWasteTypes) t.id: t};
  final today = now.dateOnly;
  final byDate = <String, DayGroup>{};
  for (final e in data.events) {
    final type = typeById[e.wasteTypeId];
    if (type == null) continue;
    final offset = daysBetween(today, e.date);
    if (offset < 0 || offset > horizonDays) continue;
    final key = e.date.isoDate;
    final existing = byDate[key];
    if (existing == null) {
      byDate[key] = DayGroup(date: e.date, types: [type], note: e.note);
    } else if (!existing.types.any((t) => t.id == type.id)) {
      byDate[key] = DayGroup(
        date: existing.date,
        types: [...existing.types, type]..sort((a, b) => a.displayName.compareTo(b.displayName)),
        note: existing.note ?? e.note,
      );
    }
  }
  return byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}
