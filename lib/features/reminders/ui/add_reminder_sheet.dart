import 'package:flutter/material.dart';

import '../../../data/models/reminder_rule.dart';
import '../../../l10n/app_localizations.dart';
import 'time_picker.dart';

String formatRuleTime(ReminderRule rule) =>
    '${rule.hour.toString().padLeft(2, '0')}:${rule.minute.toString().padLeft(2, '0')}';

String daysBeforeLabel(AppLocalizations l10n, int daysBefore) =>
    switch (daysBefore) {
      0 => l10n.reminderDayOf,
      1 => l10n.reminderDayBefore,
      _ => l10n.reminderTwoDaysBefore,
    };

Future<ReminderRule?> showAddReminderSheet(BuildContext context) {
  return showModalBottomSheet<ReminderRule>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _AddReminderSheet(),
  );
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  int _daysBefore = 1;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addReminder,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            RadioGroup<int>(
              groupValue: _daysBefore,
              onChanged: (v) => setState(() => _daysBefore = v!),
              child: Column(
                children: [
                  for (final d in [0, 1, 2])
                    RadioListTile<int>(
                      value: d,
                      title: Text(daysBeforeLabel(l10n, d)),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.reminderAt(_time.format(context))),
              onTap: () async {
                final picked = await showReminderTimePicker(context, _time);
                if (picked != null) setState(() => _time = picked);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                ReminderRule(
                  id: ReminderRule.newId(),
                  daysBefore: _daysBefore,
                  hour: _time.hour,
                  minute: _time.minute,
                ),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
