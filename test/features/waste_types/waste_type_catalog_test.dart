import 'package:abfallkalender/features/waste_types/domain/waste_type_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleanName strips Abfuhr prefix and whitespace', () {
    expect(WasteTypeCatalog.cleanName('Abfuhr: Biotonne'), 'Biotonne');
    expect(WasteTypeCatalog.cleanName('  Restmüll   Tonne '), 'Restmüll Tonne');
    expect(WasteTypeCatalog.cleanName('Abfuhr:'), 'Abfuhr:');
  });

  test('normalizeId transliterates and collapses', () {
    expect(WasteTypeCatalog.normalizeId('Abfuhr: Biotonne'), 'biotonne');
    expect(WasteTypeCatalog.normalizeId('Restmüll Tonne'), 'restmuell_tonne');
    expect(WasteTypeCatalog.normalizeId('Wertstofftonne / Gelber Container'),
        'wertstofftonne_gelber_container');
    expect(WasteTypeCatalog.normalizeId('   '), 'unbekannt');
  });

  test('createDefault assigns colors and icons by keyword', () {
    expect(WasteTypeCatalog.createDefault('Biotonne').color, 0xFF6D4C41);
    expect(WasteTypeCatalog.createDefault('Biotonne').icon, 'leaf');
    expect(WasteTypeCatalog.createDefault('Restmüll Tonne').color, 0xFF455A64);
    expect(WasteTypeCatalog.createDefault('Wertstofftonne / Gelber Container').color, 0xFFF9A825);
    expect(WasteTypeCatalog.createDefault('Gelber Sack').color, 0xFFF9A825);
    expect(WasteTypeCatalog.createDefault('Altpapier Tonne').color, 0xFF1E88E5);
    expect(WasteTypeCatalog.createDefault('Problemabfallsammlung').color, 0xFFD32F2F);
    expect(WasteTypeCatalog.createDefault('Altglas').color, 0xFF2E7D32);
    expect(WasteTypeCatalog.createDefault('Sperrmüll').color, 0xFF6A1B9A);
    expect(WasteTypeCatalog.createDefault('Weihnachtsbaum').color, WasteTypeCatalog.fallbackColor);
    expect(WasteTypeCatalog.createDefault('Weihnachtsbaum').icon, WasteTypeCatalog.fallbackIcon);
  });

  test('createDefault uses cleaned display name and normalized id', () {
    final t = WasteTypeCatalog.createDefault('Abfuhr: Biotonne');
    expect(t.id, 'biotonne');
    expect(t.displayName, 'Biotonne');
    expect(t.notificationsEnabled, isTrue);
  });

  test('palette and icon keys are non-empty and icon keys cover defaults', () {
    expect(WasteTypeCatalog.palette.length, greaterThanOrEqualTo(8));
    for (final key in ['leaf', 'trash', 'recycle', 'paper', 'warning', 'bottle', 'sofa']) {
      expect(WasteTypeCatalog.iconKeys, contains(key));
    }
  });
}
