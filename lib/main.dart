import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/infrastructure_providers.dart';
import 'data/repositories/json_file_event_repository.dart';
import 'data/repositories/prefs_settings_repository.dart';
import 'features/reminders/data/local_notifications_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final documents = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  final gateway = LocalNotificationsGateway(prefs);
  await gateway.initialize();

  runApp(
    ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(JsonFileEventRepository(documents)),
        settingsRepositoryProvider.overrideWithValue(PrefsSettingsRepository(prefs)),
        notificationGatewayProvider.overrideWithValue(gateway),
      ],
      child: const AbfallkalenderApp(),
    ),
  );
}
