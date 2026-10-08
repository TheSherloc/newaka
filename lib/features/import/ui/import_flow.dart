import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../core/result.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/providers/app_data_provider.dart';
import '../../waste_types/domain/waste_type_catalog.dart';
import '../domain/apply_import.dart';
import '../domain/import_selection.dart';
import '../domain/parsed_import.dart';
import '../domain/sample_data.dart';
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
    await _handleParsed(
      context,
      result,
      onApplied: () => ref.read(subscriptionProvider.notifier).markActivated(url),
    );
  }

  Future<void> importSample(BuildContext context) =>
      _handleParsed(context, Ok(sampleImport(from: ref.read(clockProvider).now())));

  /// Zeigt Vorschau, übernimmt Daten, fragt Berechtigung. Gibt `true` bei Erfolg zurück.
  Future<bool> _handleParsed(
    BuildContext context,
    Result<ParsedImport> result, {
    Future<void> Function()? onApplied,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    switch (result) {
      case Err(:final message):
        await _showError(context, message);
        return false;
      case Ok(:final value):
        final data = ref.read(appDataProvider).value;
        final current = data?.wasteTypes ?? const <WasteType>[];
        final byId = {for (final t in current) t.id: t};
        final seenIds = <String>{};
        final resolved = [
          for (final name in value.distinctRawNames)
            if (seenIds.add(WasteTypeCatalog.normalizeId(name)))
              byId[WasteTypeCatalog.normalizeId(name)] ?? WasteTypeCatalog.createDefault(name),
        ];
        final settings = ref.read(settingsRepositoryProvider);
        final stored = await settings.loadExcludedTypeIds();
        if (!context.mounted) return false;
        final choice = await showImportPreviewDialog(
          context,
          value,
          countByType(value, resolved),
          initiallyExcluded: stored,
          hasExistingData: data?.events.isNotEmpty ?? false,
        );
        if (choice == null) return false;
        final ImportOutcome outcome;
        try {
          outcome = await ref
              .read(appDataProvider.notifier)
              .applyParsedImport(filterParsedImport(value, choice.excludedTypeIds), choice.mode);
          await onApplied?.call();
        } catch (e) {
          if (context.mounted) await _showError(context, 'Speichern fehlgeschlagen: $e');
          return false;
        }
        // Die Beispieldaten teilen sich IDs mit echten Arten; ihre Auswahl darf die
        // gemerkte Entscheidung für echte Importe nicht überschreiben.
        if (value.sourceId == SampleData.sourceId) {
          if (!context.mounted) return true;
          await ensureNotificationPermission(context, ref);
          messenger.showSnackBar(SnackBar(content: Text(l10n.importSuccess(outcome.imported))));
          return true;
        }
        try {
          await settings.saveExcludedTypeIds(mergeExclusions(
            stored: stored,
            seenInImport: seenIds,
            excludedNow: choice.excludedTypeIds,
          ));
        } catch (_) {
          // Die Auswahl zu merken ist Komfort; der Import selbst ist bereits gespeichert.
        }
        if (!context.mounted) return true;
        await ensureNotificationPermission(context, ref);
        messenger.showSnackBar(SnackBar(content: Text(l10n.importSuccess(outcome.imported))));
        return true;
    }
  }

  Future<void> _showError(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importFailed),
        content: Text(message),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
      ),
    );
  }
}
