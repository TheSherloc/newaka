import '../../../data/models/waste_type.dart';

class WasteTypeCatalog {
  WasteTypeCatalog._();

  static const fallbackColor = 0xFF78909C;
  static const fallbackIcon = 'trash';

  static const List<int> palette = [
    0xFF6D4C41, // Braun
    0xFF455A64, // Dunkelgrau
    0xFFF9A825, // Gelb
    0xFF1E88E5, // Blau
    0xFFD32F2F, // Rot
    0xFF2E7D32, // Grün
    0xFF6A1B9A, // Violett
    0xFF78909C, // Neutralgrau
    0xFFEF6C00, // Orange
    0xFF00897B, // Türkis
    0xFFAD1457, // Pink
    0xFF212121, // Schwarz
  ];

  static const List<String> iconKeys = [
    'leaf', 'trash', 'recycle', 'paper', 'warning', 'bottle', 'sofa', 'tree',
  ];

  static final _prefix = RegExp(r'^(abfuhr|abholung|leerung|termin)\s*:\s*', caseSensitive: false);
  static final _spaces = RegExp(r'\s+');
  static final _nonAlnum = RegExp(r'[^a-z0-9]+');
  static final _edgeUnderscores = RegExp(r'^_+|_+$');

  static const _rules = <(List<String>, int, String)>[
    (['bio'], 0xFF6D4C41, 'leaf'),
    (['rest', 'hausmuell'], 0xFF455A64, 'trash'),
    (['wertstoff', 'gelb', 'verpackung', 'plastik'], 0xFFF9A825, 'recycle'),
    (['papier', 'karton'], 0xFF1E88E5, 'paper'),
    (['problem', 'schadstoff', 'sonder'], 0xFFD32F2F, 'warning'),
    (['glas'], 0xFF2E7D32, 'bottle'),
    (['sperr'], 0xFF6A1B9A, 'sofa'),
  ];

  static String cleanName(String raw) {
    final trimmed = raw.trim();
    final stripped = trimmed.replaceFirst(_prefix, '').replaceAll(_spaces, ' ').trim();
    return stripped.isEmpty ? trimmed : stripped;
  }

  static String normalizeId(String raw) {
    var s = cleanName(raw).toLowerCase();
    s = s
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    s = s.replaceAll(_nonAlnum, '_').replaceAll(_edgeUnderscores, '');
    return s.isEmpty ? 'unbekannt' : s;
  }

  static WasteType createDefault(String raw) {
    final id = normalizeId(raw);
    var color = fallbackColor;
    var icon = fallbackIcon;
    for (final (keywords, c, i) in _rules) {
      if (keywords.any(id.contains)) {
        color = c;
        icon = i;
        break;
      }
    }
    return WasteType(id: id, displayName: cleanName(raw), color: color, icon: icon);
  }
}
