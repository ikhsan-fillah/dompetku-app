import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';
import '../../transaction/models/transaction_model.dart';
import '../models/dashboard_summary_model.dart';
import '../models/spending_trend_point.dart';

class FinancialCalculationService {
  const FinancialCalculationService();

  List<TransactionModel> _within(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) => transactions.where((transaction) => range.contains(transaction.transactionDate)).toList();

  int totalForType(Iterable<TransactionModel> transactions, TransactionType type, DateRange range) =>
      _within(transactions, range)
          .where((transaction) => transaction.type == type)
          .fold(0, (total, transaction) => total + transaction.amount);

  DashboardSummaryModel summary(Iterable<TransactionModel> transactions, DateRange range) {
    final income = totalForType(transactions, TransactionType.income, range);
    final expense = totalForType(transactions, TransactionType.expense, range);
    return DashboardSummaryModel(income: income, expense: expense, balance: income - expense);
  }

  Map<int, int> categoryTotals(Iterable<TransactionModel> transactions, DateRange range) {
    final totals = <int, int>{};
    for (final transaction in _within(transactions, range).where((item) => item.type == TransactionType.expense)) {
      totals.update(transaction.categoryId, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
    }
    return totals;
  }

  List<SpendingTrendPoint> dailyExpenses(Iterable<TransactionModel> transactions, DateRange range) {
    final amounts = <DateTime, int>{};
    for (final transaction in _within(transactions, range).where((item) => item.type == TransactionType.expense)) {
      final day = DateTime(transaction.transactionDate.year, transaction.transactionDate.month, transaction.transactionDate.day);
      amounts.update(day, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
    }
    return amounts.entries
        .map((entry) => SpendingTrendPoint(date: entry.key, amount: entry.value))
        .toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  int budgetRemaining({required int limit, required int used}) => limit - used;

  double budgetUsage({required int limit, required int used}) => limit == 0 ? 0 : used / limit;

  double monthlyEfficiency({required int spent, required int monthlyLimit, required DateTime day}) {
    if (monthlyLimit <= 0) return 0;
    final expectedByToday = monthlyLimit * day.day / DateRange.daysInMonth(day);
    if (expectedByToday == 0) return 1;
    return (expectedByToday - spent) / expectedByToday;
  }

  double previousPeriodExpenseChange(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) {
    final current = totalForType(transactions, TransactionType.expense, range);
    final previous = totalForType(transactions, TransactionType.expense, range.previousEquivalentPeriod);
    if (previous == 0) return current == 0 ? 0 : 1;
    return (current - previous) / previous;
  }
}
