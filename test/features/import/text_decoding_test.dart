import 'dart:convert';
import 'dart:io';

import 'package:abfallkalender/features/import/domain/text_decoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes valid utf8', () {
    expect(decodeImportBytes(utf8.encode('Restmüll')), 'Restmüll');
  });

  test('strips utf8 BOM', () {
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('Datum;Art')];
    expect(decodeImportBytes(bytes), 'Datum;Art');
  });

  test('falls back to windows-1252 for latin bytes', () {
    final bytes = [...'Restm'.codeUnits, 0xFC, ...'ll'.codeUnits];
    expect(decodeImportBytes(bytes), 'Restmüll');
  });

  test('maps windows-1252 upper range (euro sign, dashes)', () {
    expect(decodeImportBytes([0x80]), '€');
    expect(decodeImportBytes([0x96]), '–');
  });

  test('fixture csv decodes with umlauts', () {
    final bytes = File('test/fixtures/augsburg_2026.csv').readAsBytesSync();
    final text = decodeImportBytes(bytes);
    expect(text, contains('Restmüll Tonne'));
    expect(text, contains('"Wochentag";"Datum";"Abfuhrart"'));
  });
}
