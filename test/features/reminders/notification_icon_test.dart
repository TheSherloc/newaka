import 'dart:io';

import 'package:abfallkalender/features/reminders/data/local_notifications_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monochrome notification icon exists for every Android density', () {
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final file = File(
        'android/app/src/main/res/drawable-$density/'
        '${LocalNotificationsGateway.androidSmallIcon}.png',
      );
      expect(file.existsSync(), isTrue, reason: '${file.path} fehlt');
    }
  });
}
