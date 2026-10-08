import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/waste_type_catalog.dart';
import 'waste_icons.dart';

/// Ergebnis des Bearbeiten-Sheets: gespeicherte Änderung oder Löschwunsch.
sealed class EditWasteTypeResult {
  const EditWasteTypeResult();
}

class WasteTypeSaved extends EditWasteTypeResult {
  const WasteTypeSaved(this.type);
  final WasteType type;
}

class WasteTypeDeleteRequested extends EditWasteTypeResult {
  const WasteTypeDeleteRequested();
}

Future<EditWasteTypeResult?> showEditWasteTypeSheet(BuildContext context, WasteType type) {
  return showModalBottomSheet<EditWasteTypeResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _EditSheet(type: type),
    ),
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.type});
  final WasteType type;
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.type.displayName);
  late int _color = widget.type.color;
  late String _icon = widget.type.icon;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _hex(int c) => '0x${c.toRadixString(16).toUpperCase().padLeft(8, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editWasteType, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: InputDecoration(labelText: l10n.name)),
          const SizedBox(height: 16),
          Text(l10n.color, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in WasteTypeCatalog.palette)
                InkWell(
                  key: Key('color-${_hex(c)}'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentFor(context, c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == _color ? theme.colorScheme.onSurface : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: c == _color ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.icon, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in WasteTypeCatalog.iconKeys)
                ChoiceChip(
                  key: Key('icon-$key'),
                  label: Icon(wasteIconFor(key), size: 20),
                  selected: key == _icon,
                  onSelected: (_) => setState(() => _icon = key),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final name = _name.text.trim();
              Navigator.pop(
                context,
                WasteTypeSaved(widget.type.copyWith(
                  displayName: name.isEmpty ? widget.type.displayName : name,
                  color: _color,
                  icon: _icon,
                )),
              );
            },
            child: Text(l10n.save),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.deleteWasteType),
            onPressed: () => Navigator.pop(context, const WasteTypeDeleteRequested()),
          ),
        ],
      ),
    );
  }
}
