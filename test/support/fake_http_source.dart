import 'dart:async';

import 'package:abfallkalender/features/import/domain/http_source.dart';

class FakeHttpSource implements HttpSource {
  final Map<String, List<int>> responses = {};
  Object? error;
  Completer<void>? gate;
  final List<Uri> requested = [];

  @override
  Future<List<int>> getBytes(Uri uri) async {
    requested.add(uri);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    final body = responses[uri.toString()];
    if (body == null) throw HttpSourceException('Server antwortete mit Status 404.');
    return body;
  }
}
