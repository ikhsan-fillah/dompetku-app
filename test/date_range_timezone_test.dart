import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contains membaca waktu UTC sebagai hari lokal', () {
    final today = DateRange(
      start: DateTime(2026, 9, 29),
      end: DateTime(2026, 9, 29),
    );
    expect(today.contains(DateTime(2026, 9, 29, 3).toUtc()), isTrue);
    expect(today.contains(DateTime(2026, 9, 28, 23, 59).toUtc()), isFalse);
  });

  test('batas rentang dari waktu UTC dinormalkan ke hari lokal', () {
    final range = DateRange(
      start: DateTime(2026, 9, 1).toUtc(),
      end: DateTime(2026, 9, 30).toUtc(),
    );
    expect(range.start, DateTime(2026, 9, 1));
    expect(range.end, DateTime(2026, 9, 30));
    expect(range.dayCount, 30);
  });
}
