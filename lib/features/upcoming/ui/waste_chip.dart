import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../waste_types/ui/waste_icons.dart';

/// Kachel einer Abfuhrart: gefülltes Farbquadrat mit Icon, daneben der Name.
class WasteChip extends StatelessWidget {
  const WasteChip({super.key, required this.type, this.compact = false});
  final WasteType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentFor(context, type.color);
    final iconSize = compact ? 24.0 : 30.0;
    final iconColor = iconColorOn(color);
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 4 : 6, compact ? 4 : 6, compact ? 10 : 14, compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(compact ? 7 : 9),
            ),
            child: Icon(wasteIconFor(type.icon), size: compact ? 15 : 18, color: iconColor),
          ),
          SizedBox(width: compact ? 8 : 10),
          Flexible(
            child: Text(
              type.displayName,
              style: (compact ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
                  ?.copyWith(color: theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
