import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:dompetku_app/features/recurring/services/recurring_generator.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringRule _monthly({int day = 1, DateTime? start, DateTime? last}) {
  return RecurringRule(
    id: 1,
    name: 'Rent',
    type: RecurringType.expense,
    categoryId: 1,
    amount: 1000000,
    frequency: RecurringFrequency.monthly,
    dayOfMonth: day,
    startDate: start ?? DateTime(2026, 1, 1),
    mode: RecurringMode.ask,
    isActive: true,
    lastGeneratedOn: last,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  const generator = RecurringGenerator();

  test('tidak membuat duplikat bila sudah dibuat untuk tanggal itu', () {
    final rule = _monthly(last: DateTime(2026, 3, 1));

    final dues = generator.dueOn(rule, DateTime(2026, 3, 20));

    expect(dues, isEmpty);
  });

  test('membuat tagihan untuk setiap bulan yang tertinggal', () {
    final rule = _monthly(last: DateTime(2026, 1, 1));

    final dues = generator.dueOn(rule, DateTime(2026, 3, 5));

    expect(dues, [DateTime(2026, 2, 1), DateTime(2026, 3, 1)]);
  });

  test('tanggal 31 jatuh di akhir bulan untuk bulan 30 hari', () {
    final rule = _monthly(day: 31, start: DateTime(2026, 1, 31));

    final dues = generator.dueOn(rule, DateTime(2026, 4, 30));

    expect(dues.last, DateTime(2026, 4, 30));
  });

  test('tahun kabisat: 29 Februari tersedia', () {
    final rule = _monthly(day: 29, start: DateTime(2028, 1, 29));

    final dues = generator.dueOn(rule, DateTime(2028, 2, 29));

    expect(dues.last, DateTime(2028, 2, 29));
  });

  test('tahun tidak kabisat: 29 Februari jatuh di 28 Februari', () {
    final rule = _monthly(day: 29, start: DateTime(2026, 1, 29));

    final dues = generator.dueOn(rule, DateTime(2026, 2, 28));

    expect(dues.last, DateTime(2026, 2, 28));
  });

  test('aturan nonaktif tidak membuat tagihan', () {
    final rule = RecurringRule(
      id: 1,
      name: 'Gym',
      type: RecurringType.expense,
      categoryId: 1,
      amount: 100000,
      frequency: RecurringFrequency.monthly,
      dayOfMonth: 1,
      startDate: DateTime(2026, 1, 1),
      mode: RecurringMode.auto,
      isActive: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    expect(generator.dueOn(rule, DateTime(2026, 3, 5)), isEmpty);
  });

  test('tagihan tidak dibuat sebelum tanggal mulai', () {
    final rule = _monthly(start: DateTime(2026, 5, 1));

    expect(generator.dueOn(rule, DateTime(2026, 4, 30)), isEmpty);
  });

  test('mingguan: satu tagihan per minggu pada hari yang dipilih', () {
    final rule = RecurringRule(
      id: 2,
      name: 'Laundry',
      type: RecurringType.expense,
      categoryId: 1,
      amount: 30000,
      frequency: RecurringFrequency.weekly,
      weekday: DateTime.monday,
      startDate: DateTime(2026, 9, 7),
      mode: RecurringMode.ask,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final dues = generator.dueOn(rule, DateTime(2026, 9, 21));

    expect(dues, [
      DateTime(2026, 9, 7),
      DateTime(2026, 9, 14),
      DateTime(2026, 9, 21),
    ]);
  });
}
