import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../domain/notification_gateway.dart';

final permissionStatusProvider = FutureProvider<NotificationPermission>(
  (ref) => ref.watch(notificationGatewayProvider).permissionStatus(),
);

final exactAlarmsProvider = FutureProvider<bool>(
  (ref) => ref.watch(notificationGatewayProvider).canScheduleExact(),
);
