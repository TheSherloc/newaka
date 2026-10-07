class WasteType {
  const WasteType({
    required this.id,
    required this.displayName,
    required this.color,
    required this.icon,
    this.notificationsEnabled = true,
  });

  final String id;
  final String displayName;
  final int color;
  final String icon;
  final bool notificationsEnabled;

  WasteType copyWith({
    String? displayName,
    int? color,
    String? icon,
    bool? notificationsEnabled,
  }) =>
      WasteType(
        id: id,
        displayName: displayName ?? this.displayName,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'color': color,
        'icon': icon,
        'notificationsEnabled': notificationsEnabled,
      };

  factory WasteType.fromJson(Map<String, dynamic> json) => WasteType(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        color: json['color'] as int,
        icon: json['icon'] as String,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      );
}
