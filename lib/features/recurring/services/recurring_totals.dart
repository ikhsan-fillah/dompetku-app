import '../models/recurring_rule.dart';

/// Total recurring per bulan. Mingguan x52/12, bulanan x1, tahunan /12.
class RecurringTotals {
  const RecurringTotals({required this.out, required this.income});

  final int out;
  final int income;

  static RecurringTotals monthly(Iterable<RecurringRule> rules) {
    var out = 0;
    var income = 0;
    for (final rule in rules.where((r) => r.isActive)) {
      final value = switch (rule.frequency) {
        RecurringFrequency.weekly => rule.amount * 52 ~/ 12,
        RecurringFrequency.monthly => rule.amount,
        RecurringFrequency.yearly => rule.amount ~/ 12,
      };
      if (rule.type == RecurringType.income) {
        income += value;
      } else {
        out += value;
      }
    }
    return RecurringTotals(out: out, income: income);
  }
}
