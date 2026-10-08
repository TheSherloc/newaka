// Rendert die App-Store-Screenshots aus den echten Screens mit Beispieldaten.
// Ausgabe: store/ios/screenshots/<Display>/<nn>-<name>.png
//
// Lauf: flutter test test/tool/render_store_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:abfallkalender/app/app_shell.dart';
import 'package:abfallkalender/app/theme.dart';
import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/features/import/domain/apply_import.dart';
import 'package:abfallkalender/features/import/domain/import_selection.dart';
import 'package:abfallkalender/features/import/domain/sample_data.dart';
import 'package:abfallkalender/features/import/ui/import_preview_dialog.dart';
import 'package:abfallkalender/features/reminders/domain/notification_gateway.dart';
import 'package:abfallkalender/features/waste_types/domain/waste_type_catalog.dart';
import 'package:abfallkalender/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_notification_gateway.dart';
import '../support/in_memory_repositories.dart';
import '../support/test_container.dart';

/// App-Store-Displayklassen und ihre Pixelmaße (Hochformat).
const displays = {
  '6.9': Size(1320, 2868),
  '6.7': Size(1290, 2796),
};

/// Logische Größe des gerenderten iPhone-Bildschirms im Rahmen.
const phoneSize = Size(393, 852);
const phoneTopInset = 59.0;
const phoneBottomInset = 34.0;

/// Fester Zeitpunkt: Donnerstag, 8. Oktober 2026, laut Beispieldaten ein Biotonnen-Tag.
final now = DateTime(2026, 10, 8, 9, 41);

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(_bytes('assets/fonts/Inter-$name.ttf'));
  }
  await inter.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final icons = FontLoader('MaterialIcons')
    ..addFont(_bytes('$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf'));
  await icons.load();
}

Future<ByteData> _bytes(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.view(bytes.buffer);
}

AppData _sampleData() =>
    applyImport(current: AppData.empty, parsed: sampleImport(from: now), mode: ImportMode.replace).data;

class _Shot extends StatelessWidget {
  const _Shot({required this.headline, required this.app});
  final String headline;
  final Widget app;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: NewakaColors.accent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 72, 32, 36),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 34,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  child: _PhoneFrame(child: app),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NewakaColors.ink,
        borderRadius: BorderRadius.circular(56),
        boxShadow: const [
          BoxShadow(color: Color(0x4D000000), blurRadius: 40, offset: Offset(0, 20)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(
          width: phoneSize.width,
          height: phoneSize.height,
          child: Stack(
            children: [
              MediaQuery(
                data: const MediaQueryData(
                  size: phoneSize,
                  devicePixelRatio: 3,
                  padding: EdgeInsets.only(top: phoneTopInset, bottom: phoneBottomInset),
                  viewPadding: EdgeInsets.only(top: phoneTopInset, bottom: phoneBottomInset),
                ),
                child: child,
              ),
              const Positioned(left: 0, right: 0, top: 0, child: _StatusBar()),
              const Positioned(left: 0, right: 0, bottom: 0, child: _HomeIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: NewakaColors.ink);
    return SizedBox(
      height: phoneTopInset,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 18, 30, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('9:41', style: style),
            Container(
              width: 124,
              height: 36,
              decoration: BoxDecoration(color: NewakaColors.ink, borderRadius: BorderRadius.circular(18)),
            ),
            const Row(
              children: [
                Icon(Icons.signal_cellular_alt, size: 17, color: NewakaColors.ink),
                SizedBox(width: 5),
                Icon(Icons.wifi, size: 17, color: NewakaColors.ink),
                SizedBox(width: 5),
                Icon(Icons.battery_full, size: 19, color: NewakaColors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: phoneBottomInset,
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(color: NewakaColors.ink, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }
}

Widget _app(List<Override> overrides, {Widget home = const AppShell()}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: home,
    ),
  );
}

List<Override> _overrides({AppData? data}) => testOverrides(
      events: InMemoryEventRepository(data ?? _sampleData()),
      settings: InMemorySettingsRepository(),
      gateway: FakeNotificationGateway()..permission = NotificationPermission.granted,
      clock: FixedClock(now),
      isIos: true,
    );

Future<void> _capture(WidgetTester tester, GlobalKey key, String display, String name) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('store/ios/screenshots/$display/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}

typedef Scene = Future<void> Function(WidgetTester tester, GlobalKey key, String headline);

Future<void> _pumpShot(WidgetTester tester, GlobalKey key, String headline, Widget app) async {
  await tester.pumpWidget(RepaintBoundary(key: key, child: _Shot(headline: headline, app: app)));
  await tester.pumpAndSettle();
}

final scenes = <String, (String, Scene)>{
  '01-start': ('Nie wieder die Tonne vergessen', (tester, key, headline) async {
    await _pumpShot(tester, key, headline, _app(_overrides()));
  }),
  '02-termine': ('Alle Abfuhrtermine im Blick', (tester, key, headline) async {
    await _pumpShot(tester, key, headline, _app(_overrides()));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await tester.pumpAndSettle();
  }),
  '03-kalender': ('Der ganze Monat auf einen Blick', (tester, key, headline) async {
    await _pumpShot(tester, key, headline, _app(_overrides()));
    await tester.tap(find.text('Kalender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();
  }),
  '04-erinnerungen': ('Erinnerung am Vorabend und am Abholtag', (tester, key, headline) async {
    await _pumpShot(tester, key, headline, _app(_overrides()));
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
  }),
  '05-import': ('Kalender der Stadt importieren, fertig', (tester, key, headline) async {
    final parsed = sampleImport(from: now);
    final resolved = [for (final n in parsed.distinctRawNames) WasteTypeCatalog.createDefault(n)];
    await _pumpShot(
      tester,
      key,
      headline,
      _app(
        _overrides(data: AppData.empty),
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showImportPreviewDialog(context, parsed, countByType(parsed, resolved), hasExistingData: false);
            });
            return const AppShell();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }),
};

void main() {
  setUpAll(() async {
    await _loadFonts();
  });

  for (final display in displays.entries) {
    for (final scene in scenes.entries) {
      testWidgets('renders ${scene.key} for ${display.key} inch', (tester) async {
        tester.view.physicalSize = display.value;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await scene.value.$2(tester, key, scene.value.$1);
        await _capture(tester, key, display.key, scene.key);
        expect(File('store/ios/screenshots/${display.key}/${scene.key}.png').lengthSync(), greaterThan(10000));
      });
    }
  }
}
