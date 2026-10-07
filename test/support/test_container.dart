import 'package:abfallkalender/app/infrastructure_providers.dart';
import 'package:abfallkalender/core/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fake_file_source.dart';
import 'fake_http_source.dart';
import 'fake_notification_gateway.dart';
import 'in_memory_repositories.dart';

List<Override> testOverrides({
  InMemoryEventRepository? events,
  InMemorySettingsRepository? settings,
  FakeNotificationGateway? gateway,
  Clock? clock,
  bool isIos = false,
  FakeHttpSource? http,
  FakeFileSource? files,
}) =>
    [
      eventRepositoryProvider.overrideWithValue(events ?? InMemoryEventRepository()),
      settingsRepositoryProvider.overrideWithValue(settings ?? InMemorySettingsRepository()),
      notificationGatewayProvider.overrideWithValue(gateway ?? FakeNotificationGateway()),
      clockProvider.overrideWithValue(clock ?? FixedClock(DateTime(2026, 1, 1, 12))),
      isIosProvider.overrideWithValue(isIos),
      httpSourceProvider.overrideWithValue(http ?? FakeHttpSource()),
      fileSourceProvider.overrideWithValue(files ?? FakeFileSource()),
    ];

ProviderContainer createTestContainer({
  InMemoryEventRepository? events,
  InMemorySettingsRepository? settings,
  FakeNotificationGateway? gateway,
  Clock? clock,
  bool isIos = false,
  FakeHttpSource? http,
}) =>
    ProviderContainer(
      overrides: testOverrides(
        events: events, settings: settings, gateway: gateway, clock: clock, isIos: isIos, http: http,
      ),
    );
