import 'dart:convert';
import 'dart:io';

import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/features/import/providers/subscription_provider.dart';
import 'package:abfallkalender/features/upcoming/providers/app_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_source.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/test_container.dart';

const url = 'https://landkreis.example/abfuhr.ics';

void main() {
  final ics = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();

  test('activate stores subscription, imports events and sets lastFetched', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository();
    final clock = FixedClock(DateTime(2026, 1, 1, 12));
    final c = createTestContainer(http: http, settings: settings, clock: clock);
    await c.read(appDataProvider.future);

    await c.read(subscriptionProvider.notifier).activate(url);

    expect(settings.subscription!.url, url);
    expect(settings.subscription!.lastFetched, DateTime(2026, 1, 1, 12));
    expect(settings.subscription!.lastError, isNull);
    expect(c.read(appDataProvider).value!.events.length, 94);
    expect(c.read(appDataProvider).value!.events.first.sourceId, 'url:landkreis.example');
  });

  test('refresh skips when fetched less than 24h ago unless forced', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: url, lastFetched: DateTime(2026, 1, 1, 2));
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);

    expect(await c.read(subscriptionProvider.notifier).refresh(), isFalse);
    expect(http.requested, isEmpty);
    expect(await c.read(subscriptionProvider.notifier).refresh(force: true), isTrue);
    expect(http.requested.length, 1);
  });

  test('refresh runs when older than 24h', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: url, lastFetched: DateTime(2025, 12, 30));
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);
    expect(await c.read(subscriptionProvider.notifier).refresh(), isTrue);
  });

  test('html response sets lastError and leaves data untouched', () async {
    final http = FakeHttpSource()..responses[url] = utf8.encode('<html>Not an ics</html>');
    final settings = InMemorySettingsRepository()..subscription = const Subscription(url: url);
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);

    expect(await c.read(subscriptionProvider.notifier).refresh(force: true), isFalse);
    expect(settings.subscription!.lastError, isNotNull);
    expect(c.read(appDataProvider).value!.events, isEmpty);
  });

  test('network error sets lastError message', () async {
    final http = FakeHttpSource()..error = const SocketException('offline');
    final settings = InMemorySettingsRepository()..subscription = const Subscription(url: url);
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.future);
    await c.read(subscriptionProvider.notifier).refresh(force: true);
    expect(settings.subscription!.lastError, contains('Netzwerk'));
  });

  test('remove clears subscription but keeps events', () async {
    final http = FakeHttpSource()..responses[url] = ics;
    final settings = InMemorySettingsRepository();
    final c = createTestContainer(http: http, settings: settings);
    await c.read(appDataProvider.future);
    await c.read(subscriptionProvider.notifier).activate(url);
    await c.read(subscriptionProvider.notifier).remove();
    expect(settings.subscription, isNull);
    expect(c.read(subscriptionProvider).value, isNull);
    expect(c.read(appDataProvider).value!.events.length, 94);
  });
}
