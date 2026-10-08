import 'parsed_import.dart';
import 'raw_pickup.dart';

/// Fiktiver Abfuhrkalender für Screenshots, App-Review und Nutzer ohne eigene Datei.
class SampleData {
  SampleData._();

  static const sourceId = 'sample';
  static const months = 12;

  /// (Name, Intervall in Tagen, Wochentag, Versatz in Wochen zum Start)
  static const types = <(String, int, int, int)>[
    ('Restmüll', 14, DateTime.tuesday, 0),
    ('Biotonne', 7, DateTime.thursday, 0),
    ('Papiertonne', 28, DateTime.tuesday, 1),
    ('Gelber Sack', 14, DateTime.friday, 1),
  ];
}

/// Erzeugt Termine ab dem Tag von [from] für zwölf Monate. Deterministisch pro Starttag.
ParsedImport sampleImport({required DateTime from}) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(start.year, start.month + SampleData.months, start.day);
  final pickups = <RawPickup>[];
  for (final (name, interval, weekday, offsetWeeks) in SampleData.types) {
    // Tage über den Konstruktor addieren: Duration-Arithmetik verschiebt über die
    // Zeitumstellung hinweg um eine Stunde und damit auf den falschen Tag.
    var date = DateTime(start.year, start.month, start.day + (weekday - start.weekday + 7) % 7 + offsetWeeks * 7);
    while (!date.isAfter(end)) {
      pickups.add(RawPickup(date: date, rawName: name));
      date = DateTime(date.year, date.month, date.day + interval);
    }
  }
  pickups.sort((a, b) => a.date.compareTo(b.date));
  return ParsedImport(sourceId: SampleData.sourceId, pickups: pickups, warnings: const []);
}
