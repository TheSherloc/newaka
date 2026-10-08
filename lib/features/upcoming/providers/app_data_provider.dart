import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/infrastructure_providers.dart';
import '../../../data/models/app_data.dart';
import '../../../data/models/waste_type.dart';
import '../../import/domain/apply_import.dart';
import '../../import/domain/parsed_import.dart';
import '../../reminders/providers/reminder_sync.dart';

class AppDataNotifier extends AsyncNotifier<AppData> {
  bool wasCorruptOnLoad = false;

  @override
  Future<AppData> build() async {
    final result = await ref.read(eventRepositoryProvider).load();
    wasCorruptOnLoad = result.wasCorrupt;
    return result.data;
  }

  Future<AppData> _loaded() => future;

  Future<void> _commit(AppData data) async {
    await ref.read(eventRepositoryProvider).save(data);
    state = AsyncData(data);
    await ref.read(reminderSyncProvider).rescheduleAll();
  }

  Future<ImportOutcome> applyParsedImport(ParsedImport parsed, ImportMode mode) async {
    final current = await _loaded();
    final outcome = applyImport(current: current, parsed: parsed, mode: mode);
    await _commit(outcome.data);
    return outcome;
  }

  Future<void> updateWasteType(WasteType type) async {
    final current = await _loaded();
    final types = current.wasteTypes.map((t) => t.id == type.id ? type : t).toList();
    await _commit(current.copyWith(wasteTypes: types));
  }

  /// Entfernt die Art samt Terminen. Die ID wandert in die Import-Abwahl,
  /// damit ein Abo-Refresh sie nicht stillschweigend wieder anlegt.
  Future<void> removeWasteType(String id) async {
    final current = await _loaded();
    await _commit(current.copyWith(
      wasteTypes: current.wasteTypes.where((t) => t.id != id).toList(),
      events: current.events.where((e) => e.wasteTypeId != id).toList(),
    ));
    final settings = ref.read(settingsRepositoryProvider);
    try {
      await settings.saveExcludedTypeIds({...await settings.loadExcludedTypeIds(), id});
    } catch (_) {
      // Komfort: Ohne den Eintrag taucht die Art beim nächsten Refresh wieder auf, mehr nicht.
    }
  }

  /// Entfernt alle Termine einer Quelle (z. B. die Beispieldaten) und danach
  /// die Abfuhrarten, die ohne Termine zurückbleiben.
  Future<void> removeSource(String sourceId) async {
    final current = await _loaded();
    final events = current.events.where((e) => e.sourceId != sourceId).toList();
    final used = events.map((e) => e.wasteTypeId).toSet();
    await _commit(AppData(
      events: events,
      wasteTypes: current.wasteTypes.where((t) => used.contains(t.id)).toList(),
    ));
  }

  Future<void> clearAll() async {
    await _loaded();
    await _commit(AppData.empty);
  }
}

final appDataProvider = AsyncNotifierProvider<AppDataNotifier, AppData>(AppDataNotifier.new);
