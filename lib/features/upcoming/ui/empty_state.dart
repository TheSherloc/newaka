import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.onImportFile, this.onEnterUrl});
  final VoidCallback? onImportFile;
  final VoidCallback? onEnterUrl;

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
            Icon(Icons.delete_sweep_outlined, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(l10n.emptyTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.emptyBody, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(onPressed: onImportFile, icon: const Icon(Icons.upload_file), label: Text(l10n.importFile)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onEnterUrl, icon: const Icon(Icons.link), label: Text(l10n.enterUrl)),
          ],
        ),
      ),
    );
  }
}
