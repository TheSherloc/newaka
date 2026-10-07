import 'dart:io';

import 'package:abfallkalender/app/lifecycle_service.dart';
import 'package:abfallkalender/core/clock.dart';
import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/subscription.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http_source.dart';
import '../support/fake_notification_gateway.dart';
import '../support/in_memory_repositories.dart';
import '../support/test_container.dart';

void main() {
  const url = 'https://a.example/x.ics';

  test('onStart reschedules when stale and refreshes stale subscription', () async {
    final gateway = FakeNotificationGateway();
    final http = FakeHttpSource()
      ..responses[url] = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();
    final settings = InMemorySettingsRepository()
      ..subscription = Subscription(url: url, lastFetched: DateTime(2025, 12, 1));
    final c = createTestContainer(
      gateway: gateway, http: http, settings: settings,
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );
    await c.read(lifecycleServiceProvider).onStart();
    expect(http.requested.length, 1);
    expect(gateway.cancelAllCount, greaterThanOrEqualTo(1));
    expect(settings.lastScheduleRun, isNotNull);
  });

  test('onResumed does nothing when everything is fresh', () async {
    final gateway = FakeNotificationGateway();
    final http = FakeHttpSource();
    final settings = InMemorySettingsRepository()
      ..lastScheduleRun = DateTime(2026, 1, 1, 10)
      ..subscription = Subscription(url: url, lastFetched: DateTime(2026, 1, 1, 10));
    final c = createTestContainer(
      gateway: gateway, http: http, settings: settings,
      events: InMemoryEventRepository(AppData(
        events: [PickupEvent(date: DateTime(2026, 1, 5), wasteTypeId: 'b', sourceId: 's')],
        wasteTypes: const [WasteType(id: 'b', displayName: 'B', color: 1, icon: 'leaf')],
      )),
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );
    await c.read(lifecycleServiceProvider).onResumed();
    expect(http.requested, isEmpty);
    expect(gateway.cancelAllCount, 0);
  });
}
