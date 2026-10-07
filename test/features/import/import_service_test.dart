import 'dart:io';

import 'package:abfallkalender/core/result.dart';
import 'package:abfallkalender/features/import/domain/import_service.dart';
import 'package:abfallkalender/features/import/domain/parsed_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = ImportService();

  ParsedImport ok(Result<ParsedImport> r) => r.when(ok: (v, _) => v, err: (m) => throw StateError(m));

  test('detects ics by content and parses fixture', () {
    final bytes = File('test/fixtures/augsburg_2026.ics').readAsBytesSync();
    final p = ok(service.parseBytes(bytes: bytes, sourceId: 'file:a.ics'));
    expect(p.pickups.length, 94);
    expect(p.sourceId, 'file:a.ics');
    expect(p.firstDate, DateTime(2026, 1, 2));
    expect(p.lastDate.year, 2026);
    expect(p.distinctRawNames.length, 5);
  });

  test('detects csv by content (cp1252) and parses fixture', () {
    final bytes = File('test/fixtures/augsburg_2026.csv').readAsBytesSync();
    final p = ok(service.parseBytes(bytes: bytes, sourceId: 'file:a.csv'));
    expect(p.pickups.length, 94);
    expect(p.distinctRawNames, contains('Restmüll Tonne'));
  });

  test('returns Err for html content', () {
    final r = service.parseText(text: '<html><body>404</body></html>', sourceId: 'url:x');
    expect(r.isOk, isFalse);
  });
}
