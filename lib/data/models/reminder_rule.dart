class ReminderRule {
  const ReminderRule({
    required this.id,
    required this.daysBefore,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  static const maxRules = 5;

  final String id;
  final int daysBefore;
  final int hour;
  final int minute;
  final bool enabled;

  static List<ReminderRule> defaults() => const [
        ReminderRule(id: 'default-evening', daysBefore: 1, hour: 18, minute: 0),
        ReminderRule(id: 'default-morning', daysBefore: 0, hour: 7, minute: 0),
      ];

  static String newId() => 'rule-${DateTime.now().microsecondsSinceEpoch}';

  ReminderRule copyWith({int? daysBefore, int? hour, int? minute, bool? enabled}) =>
      ReminderRule(
        id: id,
        daysBefore: daysBefore ?? this.daysBefore,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'daysBefore': daysBefore,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory ReminderRule.fromJson(Map<String, dynamic> json) => ReminderRule(
        id: json['id'] as String,
        daysBefore: json['daysBefore'] as int,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        enabled: json['enabled'] as bool? ?? true,
      );
}
