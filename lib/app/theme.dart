import 'package:flutter/material.dart';

/// Farbtokens von Newaka: Weiß, tiefes Grün, ruhige Grautöne mit Grünstich.
class NewakaColors {
  NewakaColors._();

  static const accent = Color(0xFF1B5E3A);
  static const accentSoft = Color(0xFFE7F1EB);
  static const ink = Color(0xFF16211B);
  static const muted = Color(0xFF66736C);
  static const line = Color(0xFFE4E9E6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F8F7);

  static const darkAccent = Color(0xFF6FCF97);
  static const darkAccentSoft = Color(0xFF1E3A2B);
  static const darkInk = Color(0xFFECF1EE);
  static const darkMuted = Color(0xFF9AA59F);
  static const darkLine = Color(0xFF26302A);
  static const darkSurface = Color(0xFF0F1512);
  static const darkSurfaceLow = Color(0xFF171E1A);
}

const _fontFamily = 'Inter';

ColorScheme _scheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(seedColor: NewakaColors.accent, brightness: brightness);
  return base.copyWith(
    primary: dark ? NewakaColors.darkAccent : NewakaColors.accent,
    onPrimary: dark ? NewakaColors.darkSurface : Colors.white,
    primaryContainer: dark ? NewakaColors.darkAccentSoft : NewakaColors.accentSoft,
    onPrimaryContainer: dark ? NewakaColors.darkAccent : NewakaColors.accent,
    surface: dark ? NewakaColors.darkSurface : NewakaColors.surface,
    onSurface: dark ? NewakaColors.darkInk : NewakaColors.ink,
    surfaceContainerLow: dark ? NewakaColors.darkSurfaceLow : NewakaColors.surfaceLow,
    surfaceContainerLowest: dark ? NewakaColors.darkSurfaceLow : NewakaColors.surface,
    onSurfaceVariant: dark ? NewakaColors.darkMuted : NewakaColors.muted,
    outlineVariant: dark ? NewakaColors.darkLine : NewakaColors.line,
    outline: dark ? NewakaColors.darkMuted : NewakaColors.muted,
  );
}

TextTheme _textTheme(ColorScheme scheme) {
  final base = Typography.material2021(platform: TargetPlatform.android).black.apply(
        fontFamily: _fontFamily,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );
  return base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontSize: 44,
      height: 1.05,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.4,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
    bodySmall: base.bodySmall?.copyWith(height: 1.4),
  );
}

ThemeData _base(Brightness brightness) {
  final scheme = _scheme(brightness);
  final text = _textTheme(scheme);
  final radius14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _fontFamily,
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
      titleSpacing: 20,
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: 56,
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: radius14,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: radius14,
        side: BorderSide(color: scheme.outlineVariant),
        foregroundColor: scheme.onSurface,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: radius14,
        textStyle: text.labelLarge,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: text.titleLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

ThemeData buildLightTheme() => _base(Brightness.light);
ThemeData buildDarkTheme() => _base(Brightness.dark);

/// Hellt dunkle Akzentfarben im Dark Theme leicht auf, damit der Kontrast stimmt.
Color accentFor(BuildContext context, int argb) {
  final color = Color(argb);
  if (Theme.of(context).brightness == Brightness.light) return color;
  final hsl = HSLColor.fromColor(color);
  if (hsl.lightness >= 0.55) return color;
  return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
}

/// Icon-Farbe auf einer gefüllten Fläche: weiß auf dunklen, Tinte auf hellen Farben.
Color iconColorOn(Color fill) =>
    ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : NewakaColors.ink;

/// Weicher Schatten für die eine hervorgehobene Karte pro Bildschirm.
List<BoxShadow> heroShadow(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) return const [];
  return const [
    BoxShadow(color: Color(0x1416211B), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A16211B), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
