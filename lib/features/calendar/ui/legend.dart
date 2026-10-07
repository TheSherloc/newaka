import 'package:flutter/material.dart';

import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/ui/waste_chip.dart';

class Legend extends StatelessWidget {
  const Legend({super.key, required this.types});
  final List<WasteType> types;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).legend,
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in types) WasteChip(type: t, compact: true)],
        ),
      ],
    );
  }
}
