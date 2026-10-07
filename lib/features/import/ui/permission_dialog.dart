import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../reminders/domain/notification_gateway.dart';

/// Fragt die Berechtigung an, falls sie noch nicht erteilt ist. Erklärender Dialog davor.
Future<void> ensureNotificationPermission(BuildContext context, WidgetRef ref) async {
  final gateway = ref.read(notificationGatewayProvider);
  if (await gateway.permissionStatus() == NotificationPermission.granted) return;
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.permissionDialogTitle),
      content: Text(l10n.permissionDialogBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.permissionDialogAllow)),
      ],
    ),
  );
  if (proceed == true) await gateway.requestPermission();
}
