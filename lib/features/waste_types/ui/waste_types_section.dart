import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/ui/section_header.dart';
import '../../upcoming/providers/app_data_provider.dart';
import 'edit_waste_type_sheet.dart';
import 'waste_icons.dart';

class WasteTypesSection extends ConsumerWidget {
  const WasteTypesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(appDataProvider).value;
    final types = data?.wasteTypes ?? const <WasteType>[];
    final notifier = ref.read(appDataProvider.notifier);

    Future<void> confirmDelete(WasteType t) async {
      final count = data?.events.where((e) => e.wasteTypeId == t.id).length ?? 0;
      final theme = Theme.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteWasteTypeConfirmTitle(t.displayName)),
          content: Text(l10n.deleteWasteTypeConfirmBody(count)),
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
      if (confirmed == true) await notifier.removeWasteType(t.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.sectionWasteTypes),
        for (final t in types)
          ListTile(
            leading: Opacity(
              opacity: t.enabled ? 1 : 0.4,
              child: CircleAvatar(
                backgroundColor: accentFor(context, t.color).withValues(alpha: 0.18),
                child: Icon(wasteIconFor(t.icon), color: accentFor(context, t.color)),
              ),
            ),
            title: Text(
              t.displayName,
              style: t.enabled ? null : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            subtitle: Text(t.enabled ? l10n.typeActive : l10n.typeHidden),
            trailing: Switch(
              value: t.enabled,
              onChanged: (v) => notifier.updateWasteType(t.copyWith(enabled: v)),
            ),
            onTap: () async {
              final result = await showEditWasteTypeSheet(context, t);
              switch (result) {
                case WasteTypeSaved(:final type):
                  await notifier.updateWasteType(type);
                case WasteTypeDeleteRequested():
                  if (context.mounted) await confirmDelete(t);
                case null:
                  break;
              }
            },
          ),
      ],
    );
  }
}
