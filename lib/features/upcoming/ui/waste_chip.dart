import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../data/models/waste_type.dart';
import '../../waste_types/ui/waste_icons.dart';

class WasteChip extends StatelessWidget {
  const WasteChip({super.key, required this.type});
  final WasteType type;

  @override
  Widget build(BuildContext context) {
    final color = accentFor(context, type.color);
    return Chip(
      avatar: Icon(wasteIconFor(type.icon), size: 18, color: color),
      label: Text(type.displayName),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
