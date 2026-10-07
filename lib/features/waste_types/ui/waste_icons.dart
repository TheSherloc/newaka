import 'package:flutter/material.dart';

IconData wasteIconFor(String key) => switch (key) {
      'leaf' => Icons.eco_outlined,
      'recycle' => Icons.recycling_outlined,
      'paper' => Icons.description_outlined,
      'warning' => Icons.warning_amber_outlined,
      'bottle' => Icons.wine_bar_outlined,
      'sofa' => Icons.weekend_outlined,
      'tree' => Icons.park_outlined,
      _ => Icons.delete_outline,
    };
