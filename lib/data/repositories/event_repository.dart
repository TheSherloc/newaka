import '../models/app_data.dart';

class LoadResult {
  const LoadResult({required this.data, required this.wasCorrupt});
  final AppData data;
  final bool wasCorrupt;
}

abstract class EventRepository {
  Future<LoadResult> load();
  Future<void> save(AppData data);
}
