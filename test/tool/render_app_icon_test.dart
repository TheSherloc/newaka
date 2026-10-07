// Erzeugt die PNG-Quellen für das App-Icon unter assets/icon/ und das
// einfarbige Benachrichtigungs-Icon unter android/app/src/main/res/drawable-*/.
//
// Lauf: flutter test test/tool/render_app_icon_test.dart
// Danach für die Launcher-Icons: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_icon_painter.dart';

/// Android-Dichten und die Kantenlänge des 24-dp-Statusleisten-Icons in Pixeln.
const notificationDensities = {
  'mdpi': 24,
  'hdpi': 36,
  'xhdpi': 48,
  'xxhdpi': 72,
  'xxxhdpi': 96,
};

Future<void> _render(
  WidgetTester tester,
  String path,
  AppIconPainter painter, {
  int pixels = 1024,
}) async {
  final key = GlobalKey();
  const logical = 512.0;
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: SizedBox(
        width: logical,
        height: logical,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixels / logical);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}

void main() {
  testWidgets('renders app icon sources', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await _render(tester, 'assets/icon/icon.png', const AppIconPainter(withBackground: true));
    await _render(
      tester,
      'assets/icon/icon_foreground.png',
      const AppIconPainter(withBackground: false, inset: 0.18),
    );

    expect(File('assets/icon/icon.png').lengthSync(), greaterThan(1000));
    expect(File('assets/icon/icon_foreground.png').lengthSync(), greaterThan(1000));
  });

  testWidgets('renders monochrome notification icon for every Android density', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    for (final entry in notificationDensities.entries) {
      final path = 'android/app/src/main/res/drawable-${entry.key}/ic_notification.png';
      await _render(
        tester,
        path,
        const AppIconPainter(withBackground: false, monochrome: true, inset: 0.04),
        pixels: entry.value,
      );
      expect(File(path).lengthSync(), greaterThan(100));
    }
  });
}
