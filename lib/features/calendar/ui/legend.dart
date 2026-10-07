import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../waste_types/ui/waste_icons.dart';

class Legend extends StatelessWidget {
  const Legend({super.key, required this.types});
  final List<WasteType> types;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).legend, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final t in types)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(wasteIconFor(t.icon), size: 16, color: accentFor(context, t.color)),
                  const SizedBox(width: 4),
                  Text(t.displayName, style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
