import 'dart:convert';
import 'dart:io';

import '../models/app_data.dart';
import 'event_repository.dart';

class JsonFileEventRepository implements EventRepository {
  JsonFileEventRepository(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}${Platform.pathSeparator}data.json');

  Future<void> _pending = Future.value();

  @override
  Future<LoadResult> load() async {
    final file = _file;
    if (!await file.exists()) {
      return const LoadResult(data: AppData.empty, wasCorrupt: false);
    }

    // Read the file contents first; if this throws an I/O error, let it propagate.
    final contents = await file.readAsString();

    // Only wrap the parse and shape step in the catch.
    try {
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return LoadResult(data: AppData.fromJson(json), wasCorrupt: false);
    } catch (_) {
      // Guard the backup itself with try/catch.
      try {
        final broken = File('${file.path}.broken');
        if (await broken.exists()) await broken.delete();
        await file.rename(broken.path);
      } catch (_) {
        // If backup fails, still return corrupt.
      }
      return const LoadResult(data: AppData.empty, wasCorrupt: true);
    }
  }

  @override
  Future<void> save(AppData data) {
    final next = _pending.then((_) => _write(data));
    _pending = next.catchError((_) {}); // keep the chain alive after a failure
    return next;
  }

  Future<void> _write(AppData data) async {
    await directory.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(_file.path);
  }
}
