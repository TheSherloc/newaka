import 'package:abfallkalender/app/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_repositories.dart';
import '../support/pump_app.dart';
import '../support/test_container.dart';

void main() {
  testWidgets('shows notice when stored data was corrupt', (tester) async {
    final repo = InMemoryEventRepository()..corruptOnLoad = true;
    await pumpApp(tester, const AppShell(), overrides: testOverrides(events: repo));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('beschädigt'), findsOneWidget);
  });
}
