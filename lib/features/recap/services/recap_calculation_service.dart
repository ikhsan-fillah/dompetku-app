import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';
import '../../dashboard/services/financial_calculation_service.dart';
import '../../transaction/models/transaction_model.dart';

class CategorySpend {
  const CategorySpend({required this.categoryId, required this.total, required this.count});

  final int categoryId;
  final int total;
  final int count;
}

class MonthlyRecap {
  const MonthlyRecap({
    required this.year,
    required this.month,
    required this.spent,
    required this.income,
    required this.daysInMonth,
    required this.isSoFar,
    required this.topCategories,
    required this.transactionCount,
  });

  final int year;
  final int month;
  final int spent;
  final int income;
  final int daysInMonth;
  final bool isSoFar;
  final List<CategorySpend> topCategories;
  final int transactionCount;

  int get net => income - spent;
  bool get hasData => transactionCount > 0;
  int get dailyAverage => daysInMonth == 0 ? 0 : spent ~/ daysInMonth;
}

class YearlyRecap {
  const YearlyRecap({
    required this.year,
    required this.totalSpent,
    required this.totalIncome,
    required this.activeMonths,
    required this.monthsSoFar,
    required this.heaviestMonth,
  });

  final int year;
  final int totalSpent;
  final int totalIncome;
  final int activeMonths;
  final int monthsSoFar;
  final int? heaviestMonth;
}

/// Semua angka recap. Memakai [FinancialCalculationService] yang sama dengan
/// Beranda agar angka untuk periode yang sama tidak berbeda.
class RecapCalculationService {
  const RecapCalculationService(this._finance);

  final FinancialCalculationService _finance;

  MonthlyRecap monthly(
    Iterable<TransactionModel> transactions, {
    required int year,
    required int month,
    required DateTime now,
  }) {
    final range = DateRange(
      start: DateTime(year, month, 1),
      end: DateTime(year, month + 1, 0),
    );
    final list = transactions.toList();
    final spent = _finance.totalForType(list, TransactionType.expense, range);
    final income = _finance.totalForType(list, TransactionType.income, range);
    final inMonth = list.where((t) => range.contains(t.transactionDate)).toList();

    final byCategory = <int, List<int>>{};
    for (final tx in inMonth.where((t) => t.type == TransactionType.expense)) {
      final bucket = byCategory.putIfAbsent(tx.categoryId, () => [0, 0]);
      bucket[0] += tx.amount;
      bucket[1] += 1;
    }
    final top = byCategory.entries
        .map((e) => CategorySpend(categoryId: e.key, total: e.value[0], count: e.value[1]))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return MonthlyRecap(
      year: year,
      month: month,
      spent: spent,
      income: income,
      daysInMonth: range.end.day,
      isSoFar: now.year == year && now.month == month,
      topCategories: top,
      transactionCount: inMonth.length,
    );
  }

  YearlyRecap yearly(
    Iterable<TransactionModel> transactions, {
    required int year,
    required DateTime now,
  }) {
    final list = transactions.toList();
    var totalSpent = 0;
    var totalIncome = 0;
    var active = 0;
    var heaviestSpent = -1;
    int? heaviest;
    for (var m = 1; m <= 12; m++) {
      final r = monthly(list, year: year, month: m, now: now);
      totalSpent += r.spent;
      totalIncome += r.income;
      if (r.hasData) active++;
      if (r.spent > heaviestSpent && r.hasData) {
        heaviestSpent = r.spent;
        heaviest = m;
      }
    }
    final monthsSoFar = year < now.year
        ? 12
        : (year == now.year ? now.month : 0);
    return YearlyRecap(
      year: year,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      activeMonths: active,
      monthsSoFar: monthsSoFar,
      heaviestMonth: heaviest,
    );
  }
}
