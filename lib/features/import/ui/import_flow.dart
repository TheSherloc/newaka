import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../core/result.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/providers/app_data_provider.dart';
import '../../waste_types/domain/waste_type_catalog.dart';
import '../domain/parsed_import.dart';
import '../providers/subscription_provider.dart';
import 'import_preview_dialog.dart';
import 'permission_dialog.dart';
import 'url_dialog.dart';

class ImportFlow {
  ImportFlow(this.ref);
  final WidgetRef ref;

  Future<void> importFromFile(BuildContext context) async {
    final picked = await ref.read(fileSourceProvider).pick();
    if (picked == null || !context.mounted) return;
    final result = ref.read(importServiceProvider).parseBytes(
          bytes: picked.bytes,
          sourceId: 'file:${picked.name}',
        );
    await _handleParsed(context, result);
  }

  Future<void> importFromUrl(BuildContext context) async {
    final url = await showUrlDialog(context);
    if (url == null || url.isEmpty || !context.mounted) return;
    final result = await ref.read(subscriptionProvider.notifier).fetchAndParse(url);
    if (!context.mounted) return;
    final imported = await _handleParsed(context, result);
    if (imported) {
      await ref.read(subscriptionProvider.notifier).markActivated(url);
    }
  }

  /// Zeigt Vorschau, übernimmt Daten, fragt Berechtigung. Gibt `true` bei Erfolg zurück.
  Future<bool> _handleParsed(BuildContext context, Result<ParsedImport> result) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    switch (result) {
      case Err(:final message):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.importFailed),
            content: Text(message),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
          ),
        );
        return false;
      case Ok(:final value):
        final current = ref.read(appDataProvider).value?.wasteTypes ?? const <WasteType>[];
        final byId = {for (final t in current) t.id: t};
        final resolved = [
          for (final name in value.distinctRawNames)
            byId[WasteTypeCatalog.normalizeId(name)] ?? WasteTypeCatalog.createDefault(name),
        ];
        final mode = await showImportPreviewDialog(context, value, resolved);
        if (mode == null) return false;
        final outcome = await ref.read(appDataProvider.notifier).applyParsedImport(value, mode);
        if (!context.mounted) return true;
        await ensureNotificationPermission(context, ref);
        messenger.showSnackBar(SnackBar(content: Text(l10n.importSuccess(outcome.imported))));
        return true;
    }
  }
}
