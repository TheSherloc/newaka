import 'dart:convert';
import 'dart:io';

import '../models/app_data.dart';
import 'event_repository.dart';

class JsonFileEventRepository implements EventRepository {
  JsonFileEventRepository(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}${Platform.pathSeparator}data.json');

  @override
  Future<LoadResult> load() async {
    final file = _file;
    if (!await file.exists()) {
      return const LoadResult(data: AppData.empty, wasCorrupt: false);
    }
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return LoadResult(data: AppData.fromJson(json), wasCorrupt: false);
    } catch (_) {
      final broken = File('${file.path}.broken');
      if (await broken.exists()) await broken.delete();
      await file.rename(broken.path);
      return const LoadResult(data: AppData.empty, wasCorrupt: true);
    }
  }

  @override
  Future<void> save(AppData data) async {
    await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(_file.path);
  }
}
