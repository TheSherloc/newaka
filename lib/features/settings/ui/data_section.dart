import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/subscription.dart';
import '../../../l10n/app_localizations.dart';
import '../../import/providers/subscription_provider.dart';
import '../../import/ui/import_flow.dart';
import '../../upcoming/providers/app_data_provider.dart';

class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sub = ref.watch(subscriptionProvider).value;
    final flow = ImportFlow(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.sectionData, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined),
          title: Text(l10n.importFile),
          onTap: () => flow.importFromFile(context),
        ),
        _SubscriptionTile(sub: sub, onEnterUrl: () => flow.importFromUrl(context)),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
          title: Text(l10n.deleteAllData, style: TextStyle(color: theme.colorScheme.error)),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteAllConfirmTitle),
                content: Text(l10n.deleteAllConfirmBody),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await ref.read(subscriptionProvider.notifier).remove();
            await ref.read(appDataProvider.notifier).clearAll();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dataDeleted)));
            }
          },
        ),
      ],
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  const _SubscriptionTile({required this.sub, required this.onEnterUrl});
  final Subscription? sub;
  final VoidCallback onEnterUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = sub;
    if (s == null) {
      return ListTile(
        leading: const Icon(Icons.link),
        title: Text(l10n.subscription),
        subtitle: Text(l10n.subscriptionNone),
        trailing: TextButton(onPressed: onEnterUrl, child: Text(l10n.enterUrl)),
      );
    }
    final fetched = s.lastFetched == null
        ? l10n.subscriptionNeverFetched
        : l10n.subscriptionLastFetched(DateFormat('d. MMM yyyy, HH:mm', 'de').format(s.lastFetched!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.link),
          title: Text(s.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fetched),
              if (s.lastError != null)
                Text(l10n.subscriptionError(s.lastError!), style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refreshNow),
                onPressed: () => ref.read(subscriptionProvider.notifier).refresh(force: true),
              ),
              TextButton(
                onPressed: () => ref.read(subscriptionProvider.notifier).remove(),
                child: Text(l10n.removeSubscription),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
