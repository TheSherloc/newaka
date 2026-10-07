import 'package:abfallkalender/app/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/test_container.dart';

void main() {
  testWidgets('shows three tabs and switches', (tester) async {
    await pumpApp(tester, const AppShell(), overrides: testOverrides());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    await tester.tap(find.text('Kalender'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-calendar')), findsOneWidget);
  });
}
