import 'dart:convert';
import 'dart:io';

import 'package:abfallkalender/features/import/domain/file_source.dart';
import 'package:abfallkalender/features/import/ui/import_flow.dart';
import 'package:abfallkalender/features/reminders/domain/notification_gateway.dart';
import 'package:abfallkalender/features/upcoming/ui/upcoming_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_file_source.dart';
import '../../support/fake_http_source.dart';
import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

class _Host extends ConsumerWidget {
  const _Host();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ImportFlow(ref);
    return UpcomingScreen(
      onImportFile: () => flow.importFromFile(context),
      onEnterUrl: () => flow.importFromUrl(context),
    );
  }
}

void main() {
  final ics = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();

  testWidgets('file import: preview, merge, success, permission dialog', (tester) async {
    final files = FakeFileSource()..next = PickedFile(name: 'a.ics', bytes: ics);
    final repo = InMemoryEventRepository();
    final gateway = FakeNotificationGateway();
    await pumpApp(tester, const _Host(),
        overrides: testOverrides(files: files, events: repo, gateway: gateway));

    await tester.tap(find.text('Datei importieren'));
    await tester.pumpAndSettle();

    expect(find.text('Import prüfen'), findsOneWidget);
    expect(find.textContaining('94 Termine'), findsOneWidget);
    expect(find.text('Biotonne'), findsOneWidget);
    await tester.tap(find.text('Zusammenführen'));
    await tester.pumpAndSettle();

    expect(repo.data.events.length, 94);
    expect(find.text('Erinnerungen erlauben'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(gateway.requestCount, 1);
    expect(find.textContaining('94 Termine importiert'), findsOneWidget);
  });

  testWidgets('file import: cancel in preview changes nothing', (tester) async {
    final files = FakeFileSource()..next = PickedFile(name: 'a.ics', bytes: ics);
    final repo = InMemoryEventRepository();
    await pumpApp(tester, const _Host(), overrides: testOverrides(files: files, events: repo));
    await tester.tap(find.text('Datei importieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repo.saveCount, 0);
  });

  testWidgets('file import: unparsable file shows error', (tester) async {
    final files = FakeFileSource()..next = PickedFile(name: 'x.txt', bytes: utf8.encode('hallo'));
    await pumpApp(tester, const _Host(), overrides: testOverrides(files: files));
    await tester.tap(find.text('Datei importieren'));
    await tester.pumpAndSettle();
    expect(find.text('Import fehlgeschlagen'), findsOneWidget);
    expect(find.textContaining('Datum'), findsOneWidget);
  });

  testWidgets('url import: dialog, preview, activates subscription', (tester) async {
    const url = 'https://lk.example/a.ics';
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository();
    final gateway = FakeNotificationGateway()..permission = NotificationPermission.granted;
    await pumpApp(tester, const _Host(),
        overrides: testOverrides(http: http, settings: settings, gateway: gateway));

    await tester.tap(find.text('URL eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), url);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Import prüfen'), findsOneWidget);
    await tester.tap(find.text('Zusammenführen'));
    await tester.pumpAndSettle();

    expect(settings.subscription!.url, url);
    expect(find.text('Erinnerungen erlauben'), findsNothing);
  });
}
