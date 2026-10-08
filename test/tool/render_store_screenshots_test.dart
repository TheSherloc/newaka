// Rendert die App-Store-Screenshots und die Creative Assets (Kopfzeile der
// Produktseite, Suchergebnisse) aus den echten Screens mit Beispieldaten.
// Ausgabe: store/ios/screenshots/<Display>/<nn>-<name>.png
//          store/ios/creative/header.png, store/ios/creative/search.png
// Apple lehnt Bilder mit Alphakanal ab, deshalb werden die PNGs ohne Alpha kodiert.
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
import 'package:image/image.dart' as img;

import '../support/fake_notification_gateway.dart';
import '../support/in_memory_repositories.dart';
import '../support/test_container.dart';

/// App-Store-Displayklassen und ihre Pixelmaße (Hochformat).
/// 6.3 ("Dynamic Island, mittel") ist Pflicht, 6.9 ("Dynamic Island, groß") deckt die großen Geräte ab.
const displays = {
  '6.9': Size(1320, 2868),
  '6.3': Size(1206, 2622),
};

/// Creative Assets: Kopfzeile der Produktseite (21:9) und Suchergebnisse (3:2).
const creativeHeader = Size(3840, 1646);
const creativeSearch = Size(3840, 2560);

/// Logische Größe des gerenderten iPhone-Bildschirms im Rahmen.
const phoneSize = Size(393, 852);
const framePadding = 12.0;
const frameWidth = 393 + 2 * framePadding;
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
      padding: const EdgeInsets.all(framePadding),
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

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
    final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: raw!.buffer,
      numChannels: 4,
    );
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(img.encodePng(rgba.convert(numChannels: 3)), flush: true);
  });
}

/// Kopfzeile und Suchergebnis-Grafik: Wortmarke und Slogan links, Startscreen rechts,
/// der nach unten aus dem Bild läuft. Der Fokus bleibt in der Bildmitte.
class _CreativeAsset extends StatelessWidget {
  const _CreativeAsset({required this.app, required this.phoneScale, required this.phoneTop});
  final Widget app;
  final double phoneScale;
  final double phoneTop;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: NewakaColors.accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Positioned(
                  left: w * 0.12,
                  top: 0,
                  bottom: 0,
                  width: w * 0.36,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Newaka',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: w * 0.055,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: w * 0.012),
                      Text(
                        'Nie wieder die Tonne vergessen',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: w * 0.024,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: w * 0.56,
                  top: phoneTop,
                  bottom: 0,
                  width: frameWidth * phoneScale,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: double.infinity,
                      child: SizedBox(
                        width: frameWidth * phoneScale,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          child: _PhoneFrame(child: app),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
        final path = 'store/ios/screenshots/${display.key}/${scene.key}.png';
        await _capture(tester, key, path);
        expect(File(path).lengthSync(), greaterThan(10000));
      });
    }
  }

  for (final (name, size, scale, top) in [
    ('header', creativeHeader, 1.45, 60.0),
    ('search', creativeSearch, 1.6, 90.0),
  ]) {
    testWidgets('renders creative asset $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: _CreativeAsset(app: _app(_overrides()), phoneScale: scale, phoneTop: top),
      ));
      await tester.pumpAndSettle();
      final path = 'store/ios/creative/$name.png';
      await _capture(tester, key, path);
      expect(File(path).lengthSync(), greaterThan(10000));
    });
  }
}
