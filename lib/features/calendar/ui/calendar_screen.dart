import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../data/models/waste_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../upcoming/providers/app_data_provider.dart';
import '../../upcoming/ui/waste_chip.dart';
import '../domain/events_by_day.dart';
import 'legend.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final today = ref.read(clockProvider).now().dateOnly;
    _focused = today;
    _selected = today;
  }

  void _jumpToToday() {
    final today = ref.read(clockProvider).now().dateOnly;
    setState(() {
      _focused = today;
      _selected = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = ref.watch(appDataProvider).value;
    final byDay = data == null ? const <String, List<WasteType>>{} : eventsByDay(data);
    final types = data?.wasteTypes ?? const <WasteType>[];
    final selectedTypes = byDay[_selected.isoDate] ?? const <WasteType>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabCalendar),
        actions: [
          IconButton(tooltip: l10n.calendarToday, icon: const Icon(Icons.today), onPressed: _jumpToToday),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          TableCalendar<WasteType>(
            locale: 'de_DE',
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Monat'},
            rowHeight: 56,
            daysOfWeekHeight: 28,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleMedium!,
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              headerPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: theme.textTheme.labelMedium!.copyWith(color: scheme.onSurfaceVariant),
              weekendStyle: theme.textTheme.labelMedium!.copyWith(color: scheme.onSurfaceVariant),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: theme.textTheme.bodyLarge!,
              weekendTextStyle: theme.textTheme.bodyLarge!,
              outsideTextStyle: theme.textTheme.bodyLarge!.copyWith(color: scheme.outlineVariant),
              todayDecoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: theme.textTheme.bodyLarge!.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              selectedTextStyle: theme.textTheme.bodyLarge!.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
              markersMaxCount: 4,
              cellMargin: const EdgeInsets.all(5),
            ),
            selectedDayPredicate: (day) => isSameDay(day, _selected),
            eventLoader: (day) => byDay[day.isoDate] ?? const [],
            onDaySelected: (selected, focused) => setState(() {
              _selected = selected.dateOnly;
              _focused = focused;
            }),
            onPageChanged: (focused) => _focused = focused,
            calendarBuilders: CalendarBuilders<WasteType>(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                final onSelected = isSameDay(day, _selected);
                return Positioned(
                  bottom: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in events.take(4))
                        Container(
                          key: Key('marker-${day.isoDate}-${t.id}'),
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: onSelected ? scheme.onPrimary : accentFor(context, t.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d. MMMM', 'de').format(_selected),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  if (selectedTypes.isEmpty)
                    Text(
                      l10n.noPickupsThisDay,
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    )
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: [for (final t in selectedTypes) WasteChip(type: t)]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (types.isNotEmpty) Legend(types: types),
        ],
      ),
    );
  }
}
