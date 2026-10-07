import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/upcoming_groups.dart';
import 'next_pickup_card.dart' show relativeLabel;
import 'waste_chip.dart';

/// Ein Tag in der Liste: Datumsblock links, relative Angabe und Kacheln rechts.
class DayGroupCard extends StatelessWidget {
  const DayGroupCard({
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
    final soon = daysFromNow <= 1;
    final dayNumber = DateFormat('d', 'de').format(group.date);
    final weekday = DateFormat('EEE', 'de').format(group.date);
    final month = DateFormat('MMM', 'de').format(group.date);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    dayNumber,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: soon ? scheme.primary : scheme.onSurface,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$weekday $month',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relativeLabel(l10n, daysFromNow),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: soon ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final t in group.types) WasteChip(type: t, compact: true)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
