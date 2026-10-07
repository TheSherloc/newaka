import '../../../core/dates.dart';
import '../../../data/models/app_data.dart';
import '../../../data/models/waste_type.dart';

Map<String, List<WasteType>> eventsByDay(AppData data) {
  final typeById = {for (final t in data.wasteTypes) t.id: t};
  final out = <String, List<WasteType>>{};
  for (final e in data.events) {
    final type = typeById[e.wasteTypeId];
    if (type == null) continue;
    final list = out.putIfAbsent(e.date.isoDate, () => []);
    if (!list.any((t) => t.id == type.id)) {
      list.add(type);
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
  }
  return out;
}
