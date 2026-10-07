// Erzeugt die PNG-Quellen für das App-Icon unter assets/icon/.
//
// Lauf: flutter test test/tool/render_app_icon_test.dart
// Danach: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_icon_painter.dart';

Future<void> _render(WidgetTester tester, String path, AppIconPainter painter) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: SizedBox(
        width: 512,
        height: 512,
        child: CustomPaint(painter: painter),
      ),
    ),
  );
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2); // 1024 px
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
}
