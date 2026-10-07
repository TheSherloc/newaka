import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/upcoming_groups.dart';
import 'next_pickup_card.dart' show relativeLabel;
import 'waste_chip.dart';

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
    final color = accentFor(context, group.types.first.color);
    final title = daysFromNow <= 1
        ? relativeLabel(l10n, daysFromNow)
        : DateFormat('EEEE, d. MMM', 'de').format(group.date);
    final subtitle = daysFromNow <= 1
        ? DateFormat('d. MMMM', 'de').format(group.date)
        : relativeLabel(l10n, daysFromNow);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in group.types) WasteChip(type: t),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
