import 'pickup_event.dart';
import 'waste_type.dart';

class AppData {
  const AppData({required this.events, required this.wasteTypes});

  static const schemaVersion = 1;
  static const empty = AppData(events: [], wasteTypes: []);

  final List<PickupEvent> events;
  final List<WasteType> wasteTypes;

  /// Nur eingeschaltete Arten; alles Sichtbare in der App leitet sich hieraus ab.
  List<WasteType> get activeWasteTypes => [for (final t in wasteTypes) if (t.enabled) t];

  AppData copyWith({List<PickupEvent>? events, List<WasteType>? wasteTypes}) =>
      AppData(events: events ?? this.events, wasteTypes: wasteTypes ?? this.wasteTypes);

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'events': events.map((e) => e.toJson()).toList(),
        'wasteTypes': wasteTypes.map((t) => t.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        events: (json['events'] as List<dynamic>)
            .map((e) => PickupEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        wasteTypes: (json['wasteTypes'] as List<dynamic>)
            .map((t) => WasteType.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
