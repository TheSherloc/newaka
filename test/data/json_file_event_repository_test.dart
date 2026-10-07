import 'dart:io';

import 'package:abfallkalender/data/models/app_data.dart';
import 'package:abfallkalender/data/models/pickup_event.dart';
import 'package:abfallkalender/data/models/waste_type.dart';
import 'package:abfallkalender/data/repositories/json_file_event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('abfall_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('load on missing file returns empty, not corrupt', () async {
    final repo = JsonFileEventRepository(dir);
    final r = await repo.load();
    expect(r.data.events, isEmpty);
    expect(r.wasCorrupt, isFalse);
  });

  test('save then load roundtrips and leaves no temp file', () async {
    final repo = JsonFileEventRepository(dir);
    await repo.save(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'b', sourceId: 's')],
      wasteTypes: const [WasteType(id: 'b', displayName: 'B', color: 1, icon: 'leaf')],
    ));
    final r = await repo.load();
    expect(r.data.events.single.key, '2026-01-02|b');
    expect(File('${dir.path}/data.json').existsSync(), isTrue);
    expect(File('${dir.path}/data.json.tmp').existsSync(), isFalse);
  });

  test('corrupt file is backed up and empty data returned', () async {
    File('${dir.path}/data.json').writeAsStringSync('{not json');
    final repo = JsonFileEventRepository(dir);
    final r = await repo.load();
    expect(r.wasCorrupt, isTrue);
    expect(r.data.events, isEmpty);
    expect(File('${dir.path}/data.json.broken').existsSync(), isTrue);
    expect(File('${dir.path}/data.json').existsSync(), isFalse);
  });

  test('save overwrites existing file', () async {
    final repo = JsonFileEventRepository(dir);
    await repo.save(AppData.empty);
    await repo.save(AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'b', sourceId: 's')],
      wasteTypes: const [],
    ));
    expect((await repo.load()).data.events.length, 1);
  });

  test('valid JSON with wrong shape is treated as corrupt', () async {
    File('${dir.path}/data.json').writeAsStringSync('[]');
    final repo = JsonFileEventRepository(dir);
    final r = await repo.load();
    expect(r.wasCorrupt, isTrue);
    expect(File('${dir.path}/data.json.broken').existsSync(), isTrue);
  });

  test('concurrent saves do not interfere and last write wins', () async {
    final repo = JsonFileEventRepository(dir);
    final a = AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 2), wasteTypeId: 'a', sourceId: 's')],
      wasteTypes: const [],
    );
    final b = AppData(
      events: [PickupEvent(date: DateTime(2026, 1, 3), wasteTypeId: 'b', sourceId: 's')],
      wasteTypes: const [],
    );
    await Future.wait([repo.save(a), repo.save(b)]);
    final r = await repo.load();
    expect(r.wasCorrupt, isFalse);
    expect(r.data.events.single.wasteTypeId, 'b');
    expect(File('${dir.path}/data.json.tmp').existsSync(), isFalse);
  });
}
