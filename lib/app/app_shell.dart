import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../features/calendar/ui/calendar_screen.dart';
import '../features/import/ui/import_flow.dart';
import '../features/reminders/providers/permission_status_provider.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/upcoming/providers/app_data_provider.dart';
import '../features/upcoming/ui/upcoming_screen.dart';
import 'lifecycle_service.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      var corrupt = false;
      try {
        await ref.read(appDataProvider.future);
        corrupt = ref.read(appDataProvider.notifier).wasCorruptOnLoad;
      } catch (_) {
        // Ladefehler werden vom AppDataProvider-Zustand in der UI angezeigt;
        // der Start-Ablauf muss trotzdem weiterlaufen.
      }
      if (!mounted) return;
      if (corrupt) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).corruptDataNotice),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      await ref.read(lifecycleServiceProvider).onStart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(permissionStatusProvider);
      ref.invalidate(exactAlarmsProvider);
      ref.read(lifecycleServiceProvider).onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          Builder(
            key: const Key('tab-home'),
            builder: (context) {
              final flow = ImportFlow(ref);
              return UpcomingScreen(
                onImportFile: () => flow.importFromFile(context),
                onEnterUrl: () => flow.importFromUrl(context),
              );
            },
          ),
          const CalendarScreen(key: Key('tab-calendar')),
          const SettingsScreen(key: Key('tab-settings')),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l10n.tabHome),
            NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month_rounded), label: l10n.tabCalendar),
            NavigationDestination(icon: const Icon(Icons.tune_outlined), selectedIcon: const Icon(Icons.tune_rounded), label: l10n.tabSettings),
          ],
        ),
      ),
    );
  }
}
