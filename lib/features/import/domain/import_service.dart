import '../../../core/result.dart';
import 'csv_parser.dart';
import 'ics_parser.dart';
import 'parsed_import.dart';
import 'text_decoding.dart';

class ImportService {
  ImportService({IcsParser? ics, CsvParser? csv})
      : _ics = ics ?? IcsParser(),
        _csv = csv ?? CsvParser();

  final IcsParser _ics;
  final CsvParser _csv;

  Result<ParsedImport> parseBytes({required List<int> bytes, required String sourceId}) =>
      parseText(text: decodeImportBytes(bytes), sourceId: sourceId);

  Result<ParsedImport> parseText({required String text, required String sourceId}) {
    final result = IcsParser.looksLikeIcs(text) ? _ics.parse(text) : _csv.parse(text);
    return result.when(
      ok: (pickups, warnings) => Ok(
        ParsedImport(sourceId: sourceId, pickups: pickups, warnings: warnings),
        warnings: warnings,
      ),
      err: (message) => Err(message),
    );
  }
}
