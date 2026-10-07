import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../reminders/ui/reminders_section.dart';
import '../../waste_types/ui/waste_types_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          RemindersSection(),
          Divider(),
          WasteTypesSection(),
          Divider(),
        ],
      ),
    );
  }
}
