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
            leading: CircleAvatar(
              backgroundColor: accentFor(context, t.color).withValues(alpha: 0.18),
              child: Icon(wasteIconFor(t.icon), color: accentFor(context, t.color)),
            ),
            title: Text(t.displayName),
            subtitle: Text(l10n.notifyForType),
            trailing: Switch(
              value: t.notificationsEnabled,
              onChanged: (v) => notifier.updateWasteType(t.copyWith(notificationsEnabled: v)),
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
