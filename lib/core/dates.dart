extension DateOnlyX on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  String get isoDate =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Kalendertage von [from] bis [to], unabhängig von Sommer-/Winterzeit.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

DateTime? _buildDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final d = DateTime(year, month, day);
  if (d.month != month || d.day != day) return null; // z. B. 31.02.
  return d;
}

final _iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
final _german = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');

DateTime? parseIsoDate(String input) {
  final m = _iso.firstMatch(input.trim());
  if (m == null) return null;
  return _buildDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

DateTime? parseGermanDate(String input) {
  final m = _german.firstMatch(input.trim());
  if (m == null) return null;
  return _buildDate(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
}

DateTime? parseFlexibleDate(String input) =>
    parseIsoDate(input) ?? parseGermanDate(input);
