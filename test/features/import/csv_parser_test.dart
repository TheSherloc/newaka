import 'dart:io';

import 'package:abfallkalender/core/result.dart';
import 'package:abfallkalender/features/import/domain/csv_parser.dart';
import 'package:abfallkalender/features/import/domain/raw_pickup.dart';
import 'package:abfallkalender/features/import/domain/text_decoding.dart';
import 'package:flutter_test/flutter_test.dart';

List<RawPickup> okValue(Result<List<RawPickup>> r) =>
    r.when(ok: (v, _) => v, err: (m) => throw StateError(m));

void main() {
  final parser = CsvParser();

  test('parses fixture csv (semicolon, quoted, German dates)', () {
    final text = decodeImportBytes(File('test/fixtures/augsburg_2026.csv').readAsBytesSync());
    final ps = okValue(parser.parse(text));
    expect(ps.length, 94);
    expect(ps.first.date, DateTime(2026, 1, 2));
    expect(ps.first.rawName, 'Biotonne');
    expect(ps[1].rawName, 'Restmüll Tonne');
    expect(ps.first.note, isNull);
  });

  test('parses comma separated with ISO dates and English headers, CRLF', () {
    const text = 'Date,Type\r\n2026-02-03,Paper\r\n2026-02-10,"Bio, Garden"\r\n';
    final ps = okValue(parser.parse(text));
    expect(ps.length, 2);
    expect(ps[1].rawName, 'Bio, Garden');
    expect(ps[1].date, DateTime(2026, 2, 10));
  });

  test('works without header using column heuristics', () {
    const text = 'Freitag;02.01.2026;Biotonne\nFreitag;09.01.2026;Restmüll\n';
    final ps = okValue(parser.parse(text));
    expect(ps.length, 2);
    expect(ps[1].rawName, 'Restmüll');
  });

  test('handles escaped quotes', () {
    const text = 'Datum;Art\n02.01.2026;"Tonne ""gelb"""\n';
    expect(okValue(parser.parse(text)).single.rawName, 'Tonne "gelb"');
  });

  test('skips rows with invalid dates and warns', () {
    const text = 'Datum;Art\n02.01.2026;Bio\nkein Datum;Bio\n\n03.01.2026;Rest\n';
    final r = parser.parse(text);
    expect(okValue(r).length, 2);
    expect(r.when(ok: (_, w) => w.single, err: (m) => m), contains('1'));
  });

  test('returns Err for empty and for no recognizable columns', () {
    expect(parser.parse('').isOk, isFalse);
    expect(parser.parse('a;b\nc;d\n').isOk, isFalse);
    final msg = parser.parse('a;b\nc;d\n').when(ok: (_, _) => '', err: (m) => m);
    expect(msg, contains('Datum'));
  });
}
