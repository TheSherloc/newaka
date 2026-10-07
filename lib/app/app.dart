import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_shell.dart';
import 'theme.dart';

class AbfallkalenderApp extends StatelessWidget {
  const AbfallkalenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppShell(),
    );
  }
}
