import '../../core/dates.dart';

class PickupEvent {
  PickupEvent({
    required DateTime date,
    required this.wasteTypeId,
    required this.sourceId,
    this.note,
  }) : date = date.dateOnly;

  final DateTime date;
  final String wasteTypeId;
  final String sourceId;
  final String? note;

  String get key => '${date.isoDate}|$wasteTypeId';

  Map<String, dynamic> toJson() => {
        'date': date.isoDate,
        'wasteTypeId': wasteTypeId,
        'sourceId': sourceId,
        'note': note,
      };

  factory PickupEvent.fromJson(Map<String, dynamic> json) => PickupEvent(
        date: parseIsoDate(json['date'] as String)!,
        wasteTypeId: json['wasteTypeId'] as String,
        sourceId: json['sourceId'] as String,
        note: json['note'] as String?,
      );

  @override
  bool operator ==(Object other) => other is PickupEvent && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
