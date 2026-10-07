import '../../../data/models/waste_type.dart';
import '../../waste_types/domain/waste_type_catalog.dart';
import 'parsed_import.dart';

/// Eine erkannte Abfuhrart mit der Anzahl ihrer Termine im Import.
class TypeCount {
  const TypeCount({required this.type, required this.count});
  final WasteType type;
  final int count;
}

/// Zählt die Termine pro aufgelöster Abfuhrart, in der Reihenfolge von [resolved].
List<TypeCount> countByType(ParsedImport parsed, List<WasteType> resolved) {
  final counts = <String, int>{};
  for (final p in parsed.pickups) {
    final id = WasteTypeCatalog.normalizeId(p.rawName);
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return [
    for (final t in resolved) TypeCount(type: t, count: counts[t.id] ?? 0),
  ];
}

/// Entfernt alle Termine, deren Abfuhrart in [excludedTypeIds] liegt.
ParsedImport filterParsedImport(ParsedImport parsed, Set<String> excludedTypeIds) {
  if (excludedTypeIds.isEmpty) return parsed;
  return ParsedImport(
    sourceId: parsed.sourceId,
    pickups: [
      for (final p in parsed.pickups)
        if (!excludedTypeIds.contains(WasteTypeCatalog.normalizeId(p.rawName))) p,
    ],
    warnings: parsed.warnings,
  );
}

/// Ersetzt die gespeicherte Entscheidung für alle Arten, die in diesem Import
/// vorkamen, durch die aktuelle Auswahl. Arten, die nicht vorkamen, bleiben.
Set<String> mergeExclusions({
  required Set<String> stored,
  required Set<String> seenInImport,
  required Set<String> excludedNow,
}) =>
    {...stored.difference(seenInImport), ...excludedNow};
