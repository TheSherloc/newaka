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

  Future<void> clearAll() async {
    await _loaded();
    await _commit(AppData.empty);
  }
}

final appDataProvider = AsyncNotifierProvider<AppDataNotifier, AppData>(AppDataNotifier.new);
