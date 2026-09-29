import 'package:dompetku_app/core/utils/date_label.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rentang dalam satu bulan', () {
    final range = DateRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 29),
    );
    expect(DateLabel.range(range), '1 – 29 Sep 2026');
  });

  test('rentang lintas bulan dalam satu tahun', () {
    final range = DateRange(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 9, 29),
    );
    expect(DateLabel.range(range), '1 Jul – 29 Sep 2026');
  });

  test('rentang lintas tahun', () {
    final range = DateRange(
      start: DateTime(2025, 12, 1),
      end: DateTime(2026, 1, 5),
    );
    expect(DateLabel.range(range), '1 Des 2025 – 5 Jan 2026');
  });

  test('satu hari saja', () {
    final range = DateRange(
      start: DateTime(2026, 9, 29),
      end: DateTime(2026, 9, 29),
    );
    expect(DateLabel.range(range), '29 Sep 2026');
  });
}
