import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/ui/waste_chip.dart';
import '../domain/apply_import.dart';
import '../domain/parsed_import.dart';

Future<ImportMode?> showImportPreviewDialog(
  BuildContext context,
  ParsedImport parsed,
  List<WasteType> resolvedTypes,
) {
  final l10n = AppLocalizations.of(context);
  final fmt = DateFormat('d. MMM yyyy', 'de');
  return showDialog<ImportMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.importPreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importPreviewSummary(parsed.pickups.length, resolvedTypes.length)),
            Text(l10n.importPreviewRange(fmt.format(parsed.firstDate), fmt.format(parsed.lastDate))),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final t in resolvedTypes) WasteChip(type: t)]),
            if (parsed.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.warnings, style: Theme.of(context).textTheme.labelLarge),
              for (final w in parsed.warnings) Text('• $w'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, ImportMode.replace),
          child: Text(l10n.importModeReplace),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ImportMode.merge),
          child: Text(l10n.importModeMerge),
        ),
      ],
    ),
  );
}
