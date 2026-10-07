import 'package:flutter/material.dart';

/// Abschnittstitel in den Einstellungen.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
      child: Text(title, style: theme.textTheme.titleLarge),
    );
  }
}

/// Icon in einem getönten Kreis, als `leading` für Listeneinträge.
class LeadingIcon extends StatelessWidget {
  const LeadingIcon(this.icon, {super.key, this.color, this.background});
  final IconData icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background ?? scheme.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color ?? scheme.onSurfaceVariant),
    );
  }
}
