import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          TableCalendar<WasteType>(
            locale: 'de_DE',
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Monat'},
            headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              markersMaxCount: 4,
              cellMargin: const EdgeInsets.all(4),
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
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in events.take(4))
                        Container(
                          key: Key('marker-${day.isoDate}-${t.id}'),
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(color: accentFor(context, t.color), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: selectedTypes.isEmpty
                  ? Text(l10n.noPickupsThisDay, style: theme.textTheme.bodyMedium)
                  : Wrap(spacing: 8, runSpacing: 8, children: [for (final t in selectedTypes) WasteChip(type: t)]),
            ),
          ),
          const SizedBox(height: 16),
          if (types.isNotEmpty) Legend(types: types),
        ],
      ),
    );
  }
}
