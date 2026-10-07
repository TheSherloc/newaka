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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              NextPickupCard(group: groups.first, daysFromNow: daysBetween(today, groups.first.date)),
              const SizedBox(height: 20),
              for (final g in groups.skip(1)) ...[
                DayGroupCard(group: g, daysFromNow: daysBetween(today, g.date)),
                const SizedBox(height: 10),
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
    return EmptyScreen(
      icon: Icons.event_available_outlined,
      title: l10n.noUpcoming,
      body: l10n.noUpcomingHint,
      primaryLabel: l10n.importFile,
      primaryIcon: Icons.upload_file_outlined,
      onPrimary: onImportFile,
    );
  }
}
