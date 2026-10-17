import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:dompetku_app/features/recurring/services/recurring_totals.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringRule _rule(
  RecurringFrequency frequency,
  int amount, {
  RecurringType type = RecurringType.expense,
  bool active = true,
}) => RecurringRule(
  id: 1,
  name: 'x',
  type: type,
  categoryId: 1,
  amount: amount,
  frequency: frequency,
  startDate: DateTime(2026, 1, 1),
  mode: RecurringMode.ask,
  isActive: active,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('bulanan dihitung apa adanya', () {
    final totals = RecurringTotals.monthly([_rule(RecurringFrequency.monthly, 1200000)]);

    expect(totals.out, 1200000);
    expect(totals.income, 0);
  });

  test('mingguan dikali 52 dibagi 12', () {
    final totals = RecurringTotals.monthly([_rule(RecurringFrequency.weekly, 12000)]);

    expect(totals.out, 52000);
  });

  test('tahunan dibagi 12', () {
    final totals = RecurringTotals.monthly([_rule(RecurringFrequency.yearly, 1200000)]);

    expect(totals.out, 100000);
  });

  test('pemasukan dipisah dari pengeluaran', () {
    final totals = RecurringTotals.monthly([
      _rule(RecurringFrequency.monthly, 5000000, type: RecurringType.income),
      _rule(RecurringFrequency.monthly, 1000000),
    ]);

    expect(totals.income, 5000000);
    expect(totals.out, 1000000);
  });

  test('item nonaktif tidak dihitung', () {
    final totals = RecurringTotals.monthly([
      _rule(RecurringFrequency.monthly, 1000000, active: false),
    ]);

    expect(totals.out, 0);
  });
}
