import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../core/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/upcoming_groups.dart';
import '../providers/app_data_provider.dart';
import 'day_group_card.dart';
import 'empty_state.dart';
import 'next_pickup_card.dart';

class UpcomingScreen extends ConsumerWidget {
  const UpcomingScreen({super.key, this.onImportFile, this.onEnterUrl});
  final VoidCallback? onImportFile;
  final VoidCallback? onEnterUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider).now();
    final data = ref.watch(appDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          if (data.events.isEmpty) {
            return EmptyState(onImportFile: onImportFile, onEnterUrl: onEnterUrl);
          }
          final groups = upcomingGroups(data: data, now: now);
          if (groups.isEmpty) {
            return _NoUpcoming(onImportFile: onImportFile);
          }
          final today = now.dateOnly;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              NextPickupCard(group: groups.first, daysFromNow: daysBetween(today, groups.first.date)),
              const SizedBox(height: 16),
              for (final g in groups.skip(1)) ...[
                DayGroupCard(group: g, daysFromNow: daysBetween(today, g.date)),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NoUpcoming extends StatelessWidget {
  const _NoUpcoming({this.onImportFile});
  final VoidCallback? onImportFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(l10n.noUpcoming, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.noUpcomingHint, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(onPressed: onImportFile, icon: const Icon(Icons.upload_file), label: Text(l10n.importFile)),
          ],
        ),
      ),
    );
  }
}
