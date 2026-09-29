import 'package:dompetku_app/core/utils/display_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisplayName.greeting', () {
    test('kosong atau null memakai Friend', () {
      expect(DisplayName.greeting(null), 'Friend');
      expect(DisplayName.greeting(''), 'Friend');
      expect(DisplayName.greeting('   '), 'Friend');
    });

    test('nama terisi dipakai apa adanya setelah dipangkas', () {
      expect(DisplayName.greeting('  Ikhsan '), 'Ikhsan');
    });
  });

  group('DisplayName.normalize', () {
    test('menggabungkan spasi berlebih', () {
      expect(DisplayName.normalize('  Ikhsan    Fillah '), 'Ikhsan Fillah');
    });

    test('memotong nama yang terlalu panjang', () {
      final result = DisplayName.normalize('a' * 40);
      expect(result.length, DisplayName.maxLength);
    });
  });

  test('inisial huruf besar, cadangan dari Friend', () {
    expect(DisplayName.initial('ikhsan'), 'I');
    expect(DisplayName.initial(''), 'F');
  });
}
