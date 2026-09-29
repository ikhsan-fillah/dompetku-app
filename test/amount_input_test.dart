import 'package:dompetku_app/core/utils/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('menambah digit dan tombol 000', () {
    var value = '';
    value = AmountInput.apply(value, '5');
    value = AmountInput.apply(value, '000');
    expect(value, '5000');
  });

  test('nol di depan diabaikan', () {
    expect(AmountInput.apply('', '0'), '');
    expect(AmountInput.apply('', '000'), '');
    expect(AmountInput.apply('0', '7'), '7');
  });

  test('hapus digit terakhir dan aman saat kosong', () {
    expect(AmountInput.apply('1250', '⌫'), '125');
    expect(AmountInput.apply('', '⌫'), '');
  });

  test('dibatasi 12 digit', () {
    final full = '9' * AmountInput.maxDigits;
    expect(AmountInput.apply(full, '1'), full);
  });

  test('tombol tak dikenal diabaikan', () {
    expect(AmountInput.apply('12', 'x'), '12');
  });

  test('tampilan bertitik ribuan dan parse', () {
    expect(AmountInput.display(''), '0');
    expect(AmountInput.display('1250000'), '1.250.000');
    expect(AmountInput.parse(''), isNull);
    expect(AmountInput.parse('45000'), 45000);
  });
}
