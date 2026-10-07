import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/upcoming_groups.dart';
import 'waste_chip.dart';

/// Die eine hervorgehobene Karte der Startseite: großes „Morgen", Datum, Kacheln.
class NextPickupCard extends StatelessWidget {
  const NextPickupCard({
    super.key,
    required this.group,
    required this.daysFromNow,
  });
  final DayGroup group;
  final int daysFromNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final relative = relativeLabel(l10n, daysFromNow);
    final absolute = DateFormat('EEEE, d. MMMM', 'de').format(group.date);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: heroShadow(context),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.nextPickup,
            style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 6),
          Text(relative, style: theme.textTheme.displaySmall),
          const SizedBox(height: 2),
          Text(
            absolute,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in group.types) WasteChip(type: t)],
          ),
          if (group.note != null) ...[
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String relativeLabel(AppLocalizations l10n, int days) => switch (days) {
  0 => l10n.today,
  1 => l10n.tomorrow,
  _ => l10n.inDays(days),
};
