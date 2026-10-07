import 'raw_pickup.dart';

class ParsedImport {
  const ParsedImport({required this.sourceId, required this.pickups, required this.warnings});

  final String sourceId;
  final List<RawPickup> pickups;
  final List<String> warnings;

  DateTime get firstDate =>
      pickups.map((p) => p.date).reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime get lastDate =>
      pickups.map((p) => p.date).reduce((a, b) => a.isAfter(b) ? a : b);

  List<String> get distinctRawNames {
    final seen = <String>{};
    return [for (final p in pickups) if (seen.add(p.rawName)) p.rawName];
  }
}
