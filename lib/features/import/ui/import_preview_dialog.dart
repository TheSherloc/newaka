import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../upcoming/ui/waste_chip.dart';
import '../domain/apply_import.dart';
import '../domain/import_selection.dart';
import '../domain/parsed_import.dart';

/// Ergebnis der Importvorschau: gewählter Modus und abgewählte Abfuhrarten.
class ImportChoice {
  const ImportChoice({required this.mode, required this.excludedTypeIds});
  final ImportMode mode;
  final Set<String> excludedTypeIds;
}

Future<ImportChoice?> showImportPreviewDialog(
  BuildContext context,
  ParsedImport parsed,
  List<TypeCount> types, {
  Set<String> initiallyExcluded = const {},
}) {
  return showDialog<ImportChoice>(
    context: context,
    builder: (context) => _ImportPreviewDialog(
      parsed: parsed,
      types: types,
      initiallyExcluded: initiallyExcluded,
    ),
  );
}

class _ImportPreviewDialog extends StatefulWidget {
  const _ImportPreviewDialog({
    required this.parsed,
    required this.types,
    required this.initiallyExcluded,
  });

  final ParsedImport parsed;
  final List<TypeCount> types;
  final Set<String> initiallyExcluded;

  @override
  State<_ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<_ImportPreviewDialog> {
  late final Set<String> _excluded = {
    for (final t in widget.types)
      if (widget.initiallyExcluded.contains(t.type.id)) t.type.id,
  };

  int get _selectedCount =>
      widget.types.where((t) => !_excluded.contains(t.type.id)).fold(0, (s, t) => s + t.count);

  int get _selectedTypes => widget.types.length - _excluded.length;

  void _pop(ImportMode mode) =>
      Navigator.pop(context, ImportChoice(mode: mode, excludedTypeIds: Set.of(_excluded)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fmt = DateFormat('d. MMM yyyy', 'de');
    final total = widget.parsed.pickups.length;
    final canImport = _selectedCount > 0;

    return AlertDialog(
      title: Text(l10n.importPreviewTitle),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.importPreviewSelection(
                    _selectedCount, total, _selectedTypes, widget.types.length),
                style: theme.textTheme.titleSmall,
              ),
              Text(
                l10n.importPreviewRange(
                    fmt.format(widget.parsed.firstDate), fmt.format(widget.parsed.lastDate)),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(l10n.importPreviewChooseTypes, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              for (final t in widget.types)
                CheckboxListTile(
                  key: Key('type-check-${t.type.id}'),
                  value: !_excluded.contains(t.type.id),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _excluded.remove(t.type.id);
                    } else {
                      _excluded.add(t.type.id);
                    }
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: WasteChip(type: t.type),
                  subtitle: Text(l10n.importTypeCount(t.count)),
                ),
              if (widget.parsed.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l10n.warnings, style: theme.textTheme.labelLarge),
                for (final w in widget.parsed.warnings) Text('• $w'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          onPressed: canImport ? () => _pop(ImportMode.replace) : null,
          child: Text(l10n.importModeReplace),
        ),
        FilledButton(
          onPressed: canImport ? () => _pop(ImportMode.merge) : null,
          child: Text(l10n.importModeMerge),
        ),
      ],
    );
  }
}
