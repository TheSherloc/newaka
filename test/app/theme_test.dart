import 'package:abfallkalender/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iconColorOn picks white on dark fills and ink on light fills', () {
    expect(iconColorOn(const Color(0xFF6D4C41)), Colors.white); // Bio-Braun
    expect(iconColorOn(const Color(0xFF455A64)), Colors.white); // Restmüll-Grau
    expect(iconColorOn(const Color(0xFFF9A825)), NewakaColors.ink); // Wertstoff-Gelb
    expect(iconColorOn(const Color(0xFFFFFFFF)), NewakaColors.ink);
  });

  test('light and dark themes use Inter and the accent colour', () {
    final light = buildLightTheme();
    final dark = buildDarkTheme();
    expect(light.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(light.colorScheme.primary, NewakaColors.accent);
    expect(dark.colorScheme.primary, NewakaColors.darkAccent);
    expect(dark.colorScheme.surface, NewakaColors.darkSurface);
  });
}
