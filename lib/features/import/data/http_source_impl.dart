import 'dart:async';

import 'package:http/http.dart' as http;

import '../domain/http_source.dart';

class HttpSourceImpl implements HttpSource {
  static const timeout = Duration(seconds: 20);

  @override
  Future<List<int>> getBytes(Uri uri) async {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const HttpSourceException('Nur http- und https-Adressen werden unterstützt.');
    }
    final http.Response response;
    try {
      response = await http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const HttpSourceException('Zeitüberschreitung beim Laden.');
    }
    if (response.statusCode != 200) {
      throw HttpSourceException('Server antwortete mit Status ${response.statusCode}.');
    }
    return response.bodyBytes;
  }
}
