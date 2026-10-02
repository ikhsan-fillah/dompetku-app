import 'package:dompetku_app/core/utils/percent_rounding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sepertiga-sepertiga tetap berjumlah 100', () {
    final result = roundPercentages([1, 1, 1]);
    expect(result, [34, 33, 33]);
    expect(result.fold<int>(0, (a, b) => a + b), 100);
  });

  test('contoh mockup 38/22/18/12/10 tetap utuh', () {
    expect(roundPercentages([1387000, 803000, 657000, 438000, 365000]), [
      38,
      22,
      18,
      12,
      10,
    ]);
  });

  test('selalu berjumlah 100 untuk pecahan sulit', () {
    final result = roundPercentages([333, 333, 334, 1, 7, 13]);
    expect(result.fold<int>(0, (a, b) => a + b), 100);
  });

  test('kosong dan total nol', () {
    expect(roundPercentages([]), isEmpty);
    expect(roundPercentages([0, 0]), [0, 0]);
  });
}
