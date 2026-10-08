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
    final types = ref.watch(appDataProvider).value?.wasteTypes ?? const <WasteType>[];
    final notifier = ref.read(appDataProvider.notifier);

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
              final edited = await showEditWasteTypeSheet(context, t);
              if (edited != null) await notifier.updateWasteType(edited);
            },
          ),
      ],
    );
  }
}
