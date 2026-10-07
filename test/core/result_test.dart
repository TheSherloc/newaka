import 'package:abfallkalender/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ok carries value and warnings', () {
    const r = Ok<int>(3, warnings: ['w']);
    expect(r.isOk, isTrue);
    expect(r.when(ok: (v, w) => '$v${w.length}', err: (m) => m), '31');
  });

  test('Err carries message', () {
    const r = Err<int>('kaputt');
    expect(r.isOk, isFalse);
    expect(r.when(ok: (v, w) => 'ok', err: (m) => m), 'kaputt');
  });
}
