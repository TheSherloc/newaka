import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../data/models/reminder_rule.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/ui/section_header.dart';
import '../domain/notification_gateway.dart';
import '../providers/permission_status_provider.dart';
import '../providers/reminder_rules_provider.dart';
import '../providers/reminder_sync.dart';
import 'add_reminder_sheet.dart';
import 'time_picker.dart';

class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rules = ref.watch(reminderRulesProvider).value ?? const <ReminderRule>[];
    final permission = ref.watch(permissionStatusProvider).value ?? NotificationPermission.unknown;
    final exact = ref.watch(exactAlarmsProvider).value ?? true;
    final notifier = ref.read(reminderRulesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.sectionReminders),
        for (final rule in rules)
          ListTile(
            leading: LeadingIcon(rule.daysBefore == 0 ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined),
            title: Text(daysBeforeLabel(l10n, rule.daysBefore)),
            subtitle: Text(l10n.reminderAt(formatRuleTime(rule))),
            onTap: () async {
              final picked = await showReminderTimePicker(
                context,
                TimeOfDay(hour: rule.hour, minute: rule.minute),
              );
              if (picked != null) {
                await notifier.updateRule(rule.copyWith(hour: picked.hour, minute: picked.minute));
              }
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(value: rule.enabled, onChanged: (v) => notifier.updateRule(rule.copyWith(enabled: v))),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => notifier.remove(rule.id),
                ),
              ],
            ),
          ),
        ListTile(
          leading: const LeadingIcon(Icons.add),
          title: Text(rules.length >= ReminderRule.maxRules ? l10n.maxRemindersReached : l10n.addReminder),
          enabled: rules.length < ReminderRule.maxRules,
          onTap: () async {
            final rule = await showAddReminderSheet(context);
            if (rule != null) await notifier.add(rule);
          },
        ),
        ListTile(
          leading: LeadingIcon(
            permission == NotificationPermission.granted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
            color: permission == NotificationPermission.denied ? theme.colorScheme.error : null,
            background: permission == NotificationPermission.denied ? theme.colorScheme.errorContainer : null,
          ),
          title: Text(switch (permission) {
            NotificationPermission.granted => l10n.permissionGranted,
            NotificationPermission.denied => l10n.permissionDenied,
            NotificationPermission.unknown => l10n.permissionUnknown,
          }),
          subtitle: (permission == NotificationPermission.denied || !exact)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (permission == NotificationPermission.denied) Text(l10n.permissionDeniedHint),
                    if (!exact) Text(l10n.exactAlarmsMissing),
                    if (!exact)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () async {
                            await ref.read(notificationGatewayProvider).requestExactAlarms();
                            ref.invalidate(exactAlarmsProvider);
                          },
                          child: Text(l10n.requestExactAlarms),
                        ),
                      ),
                  ],
                )
              : null,
          trailing: permission == NotificationPermission.granted
              ? null
              : TextButton(
                  onPressed: () async {
                    final granted = await ref.read(notificationGatewayProvider).requestPermission();
                    if (granted) {
                      try {
                        await ref.read(reminderSyncProvider).rescheduleAll();
                      } catch (_) {
                        // Planung ist best effort.
                      }
                    }
                    ref.invalidate(permissionStatusProvider);
                    ref.invalidate(exactAlarmsProvider);
                  },
                  child: Text(l10n.requestPermission),
                ),
        ),
        ListTile(
          leading: const LeadingIcon(Icons.send_outlined),
          title: Text(l10n.sendTestNotification),
          onTap: () => ref.read(notificationGatewayProvider).showNow(
                title: l10n.testNotificationTitle,
                body: l10n.testNotificationBody,
              ),
        ),
      ],
    );
  }
}
