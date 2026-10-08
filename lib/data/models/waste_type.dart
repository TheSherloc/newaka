class WasteType {
  const WasteType({
    required this.id,
    required this.displayName,
    required this.color,
    required this.icon,
    this.enabled = true,
  });

  final String id;
  final String displayName;
  final int color;
  final String icon;

  /// Ausgeschaltete Arten werden nirgends angezeigt und lösen keine Erinnerungen aus.
  /// Ihre Termine bleiben gespeichert, Einschalten holt sie zurück.
  final bool enabled;

  WasteType copyWith({
    String? displayName,
    int? color,
    String? icon,
    bool? enabled,
  }) =>
      WasteType(
        id: id,
        displayName: displayName ?? this.displayName,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'color': color,
        'icon': icon,
        'enabled': enabled,
      };

  factory WasteType.fromJson(Map<String, dynamic> json) => WasteType(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        color: json['color'] as int,
        icon: json['icon'] as String,
        // 'notificationsEnabled' ist der Schlüssel aus Version 1.0.
        enabled: (json['enabled'] ?? json['notificationsEnabled']) as bool? ?? true,
      );
}
