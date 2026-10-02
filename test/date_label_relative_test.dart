import 'package:dompetku_app/core/utils/date_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 29, 14, 30);

  test('hari yang sama disebut Hari ini', () {
    expect(
      DateLabel.relativeDay(DateTime(2026, 9, 29, 1), now: now),
      'Hari ini',
    );
  });

  test('sehari sebelumnya disebut Kemarin', () {
    expect(
      DateLabel.relativeDay(DateTime(2026, 9, 28, 23), now: now),
      'Kemarin',
    );
  });

  test('lebih lama memakai tanggal lengkap', () {
    expect(
      DateLabel.relativeDay(DateTime(2026, 9, 20), now: now),
      '20 Sep 2026',
    );
  });

  test('lintas bulan tetap dihitung benar', () {
    expect(
      DateLabel.relativeDay(DateTime(2026, 8, 31), now: DateTime(2026, 9, 1)),
      'Kemarin',
    );
  });
}
