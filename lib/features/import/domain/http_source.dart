class HttpSourceException implements Exception {
  const HttpSourceException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class HttpSource {
  Future<List<int>> getBytes(Uri uri);
}
