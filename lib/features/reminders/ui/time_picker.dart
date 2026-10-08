import 'package:flutter/material.dart';

/// Zeitwähler im 24-Stunden-Format, unabhängig von der Systemeinstellung.
///
/// Die App zeigt Uhrzeiten überall als "18:00". Auf Geräten mit 12-Stunden-
/// Anzeige lehnt Flutters Tastatureingabe sonst Stunden ab 13 ab, obwohl das
/// Zifferblatt der deutschen Lokalisierung 0 bis 23 zeigt.
Future<TimeOfDay?> showReminderTimePicker(BuildContext context, TimeOfDay initialTime) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
}
