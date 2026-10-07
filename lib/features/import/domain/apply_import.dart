import '../../../data/models/app_data.dart';
import '../../../data/models/pickup_event.dart';
import '../../../data/models/waste_type.dart';
import '../../waste_types/domain/waste_type_catalog.dart';
import 'parsed_import.dart';

enum ImportMode { merge, replace }

class ImportOutcome {
  const ImportOutcome({required this.data, required this.imported, required this.newWasteTypes});
  final AppData data;
  final int imported;
  final List<WasteType> newWasteTypes;
}

ImportOutcome applyImport({
  required AppData current,
  required ParsedImport parsed,
  required ImportMode mode,
}) {
  final types = {for (final t in current.wasteTypes) t.id: t};
  final newTypes = <WasteType>[];

  final incoming = <String, PickupEvent>{};
  for (final p in parsed.pickups) {
    final id = WasteTypeCatalog.normalizeId(p.rawName);
    if (!types.containsKey(id)) {
      final created = WasteTypeCatalog.createDefault(p.rawName);
      types[id] = created;
      newTypes.add(created);
    }
    final event = PickupEvent(
      date: p.date,
      wasteTypeId: id,
      sourceId: parsed.sourceId,
      note: p.note,
    );
    incoming.putIfAbsent(event.key, () => event);
  }

  final base = mode == ImportMode.replace
      ? <PickupEvent>[]
      : current.events.where((e) => e.sourceId != parsed.sourceId).toList();
  final existingKeys = base.map((e) => e.key).toSet();
  final added = incoming.values.where((e) => !existingKeys.contains(e.key));

  final events = [...base, ...added]..sort((a, b) => a.date.compareTo(b.date));
  return ImportOutcome(
    data: AppData(events: events, wasteTypes: types.values.toList()),
    imported: incoming.length,
    newWasteTypes: newTypes,
  );
}
