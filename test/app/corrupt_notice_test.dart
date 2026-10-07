import 'dart:io';

import 'package:abfallkalender/app/app_shell.dart';
import 'package:abfallkalender/app/infrastructure_providers.dart';
import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/repositories/event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/fake_http_source.dart';
import '../support/fake_notification_gateway.dart';
import '../support/in_memory_repositories.dart';
import '../support/pump_app.dart';
import '../support/test_container.dart';

class _ThrowingEventRepository implements EventRepository {
  @override
  Future<LoadResult> load() async => throw const FileSystemException('locked');
  @override
  Future<void> save(AppData data) async {}
}

void main() {
  testWidgets('shows notice when stored data was corrupt', (tester) async {
    final repo = InMemoryEventRepository()..corruptOnLoad = true;
    await pumpApp(tester, const AppShell(), overrides: testOverrides(events: repo));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('beschädigt'), findsOneWidget);
  });

  testWidgets('startup continues to onStart when the load throws', (tester) async {
    final gateway = FakeNotificationGateway();
    final settings = InMemorySettingsRepository();
    await pumpApp(
      tester,
      const AppShell(),
      overrides: [
        eventRepositoryProvider.overrideWithValue(_ThrowingEventRepository()),
        settingsRepositoryProvider.overrideWithValue(settings),
        notificationGatewayProvider.overrideWithValue(gateway),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 1, 1, 12))),
        isIosProvider.overrideWithValue(false),
        httpSourceProvider.overrideWithValue(FakeHttpSource()),
        fileSourceProvider.overrideWithValue(FakeFileSource()),
      ],
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
