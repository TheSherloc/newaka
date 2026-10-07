import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/features/reminders/domain/notification_gateway.dart';
import 'package:abfallkalender/features/reminders/ui/reminders_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_notification_gateway.dart';
import '../../support/in_memory_repositories.dart';
import '../../support/pump_app.dart';
import '../../support/test_container.dart';

void main() {
  testWidgets('lists default rules, toggles and deletes, sends test notification', (tester) async {
    final settings = InMemorySettingsRepository();
    final gateway = FakeNotificationGateway()..permission = NotificationPermission.granted;
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(settings: settings, gateway: gateway));

    expect(find.text('Am Vortag'), findsOneWidget);
    expect(find.text('um 18:00'), findsOneWidget);
    expect(find.text('Am Abholtag'), findsOneWidget);
    expect(find.text('um 07:00'), findsOneWidget);
    expect(find.text('Benachrichtigungen erlaubt'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(settings.rules![0].enabled, isFalse);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    expect(settings.rules!.length, 1);

    await tester.tap(find.text('Test-Benachrichtigung senden'));
    await tester.pumpAndSettle();
    expect(gateway.shown.single.$1, 'Test');
  });

  testWidgets('add reminder via sheet', (tester) async {
    final settings = InMemorySettingsRepository();
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(settings: settings));
    await tester.tap(find.text('Erinnerung hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zwei Tage vorher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(settings.rules!.length, 3);
    expect(settings.rules!.last.daysBefore, 2);
  });

  testWidgets('shows request button when permission denied', (tester) async {
    final gateway = FakeNotificationGateway()..permission = NotificationPermission.denied;
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(gateway: gateway));
    expect(find.text('Benachrichtigungen nicht erlaubt'), findsOneWidget);
    expect(find.text('Berechtigung anfragen'), findsOneWidget);
  });

  testWidgets('granting permission reschedules reminders', (tester) async {
    final gateway = FakeNotificationGateway()
      ..permission = NotificationPermission.denied
      ..grantOnRequest = true;
    final seeded = AppData(
      events: [PickupEvent(date: DateTime(2099, 1, 5), wasteTypeId: 'bio', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'bio', displayName: 'Bio', color: 1, icon: 'leaf')],
    );
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(gateway: gateway, events: InMemoryEventRepository(seeded)));
    expect(find.textContaining('Systemeinstellungen'), findsOneWidget);
    await tester.tap(find.text('Berechtigung anfragen'));
    await tester.pumpAndSettle();
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled, isNotEmpty);
  });

  testWidgets('exact alarm button requests exact alarms', (tester) async {
    final gateway = FakeNotificationGateway()
      ..permission = NotificationPermission.granted
      ..exactAllowed = false;
    await pumpApp(tester, const Scaffold(body: RemindersSection()),
        overrides: testOverrides(gateway: gateway));
    expect(find.textContaining('Exakte Alarme sind nicht erlaubt'), findsOneWidget);
    await tester.tap(find.text('Exakte Alarme erlauben'));
    await tester.pumpAndSettle();
    expect(gateway.exactRequestCount, 1);
    expect(find.text('Exakte Alarme erlauben'), findsNothing);
  });
}
