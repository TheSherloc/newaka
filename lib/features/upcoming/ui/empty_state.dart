import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.onImportFile, this.onEnterUrl});
  final VoidCallback? onImportFile;
  final VoidCallback? onEnterUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyScreen(
      icon: Icons.inventory_2_outlined,
      title: l10n.emptyTitle,
      body: l10n.emptyBody,
      primaryLabel: l10n.importFile,
      primaryIcon: Icons.upload_file_outlined,
      onPrimary: onImportFile,
      secondaryLabel: l10n.enterUrl,
      secondaryIcon: Icons.link_rounded,
      onSecondary: onEnterUrl,
    );
  }
}

/// Leerzustand mit Symbol, Titel, Erklärung und ein bis zwei Aktionen.
class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryIcon,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, size: 44, color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 28),
              Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onPrimary,
                icon: Icon(primaryIcon),
                label: Text(primaryLabel),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: Icon(secondaryIcon),
                  label: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
