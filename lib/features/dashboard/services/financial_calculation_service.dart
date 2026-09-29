import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';
import '../../budget/models/budget_model.dart';
import '../../transaction/models/transaction_model.dart';
import '../models/budget_progress_model.dart';
import '../models/dashboard_summary_model.dart';
import '../models/spending_trend_point.dart';

class FinancialCalculationService {
  const FinancialCalculationService();

  List<TransactionModel> _within(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) => transactions.where((transaction) => range.contains(transaction.transactionDate)).toList();

  DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

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
      final day = _day(transaction.transactionDate);
      amounts.update(day, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
    }
    return amounts.entries
        .map((entry) => SpendingTrendPoint(date: entry.key, amount: entry.value))
        .toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  int budgetRemaining({required int limit, required int used}) => limit - used;

  double budgetUsage({required int limit, required int used}) => limit == 0 ? 0 : used / limit;

  /// Anggaran keseluruhan (tanpa kategori) yang berlaku pada [now].
  /// Bila ada beberapa, dipilih yang periodenya dimulai paling akhir.
  BudgetModel? activeOverallBudget(Iterable<BudgetModel> budgets, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    BudgetModel? best;
    for (final budget in budgets) {
      if (budget.categoryId != null || budget.isArchived) continue;
      final start = _day(budget.startDate);
      final end = _day(budget.endDate);
      if (today.isBefore(start) || today.isAfter(end)) continue;
      if (best == null || start.isAfter(_day(best.startDate))) best = budget;
    }
    return best;
  }

  /// Pemakaian anggaran selama periodenya sendiri, terlepas dari rentang dashboard.
  BudgetProgressModel budgetProgress(
    Iterable<TransactionModel> transactions,
    BudgetModel budget, {
    DateTime? now,
  }) {
    final today = _day(now ?? DateTime.now());
    final start = _day(budget.startDate);
    final end = _day(budget.endDate);
    final range = DateRange(start: start, end: end.isBefore(start) ? start : end);
    final used = _within(transactions, range)
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              (budget.categoryId == null || item.categoryId == budget.categoryId),
        )
        .fold<int>(0, (total, item) => total + item.amount);
    final totalDays = range.dayCount;
    final elapsed = today.isBefore(range.start)
        ? 0
        : today.isAfter(range.end)
            ? totalDays
            : today.difference(range.start).inDays + 1;
    return BudgetProgressModel(
      name: budget.name,
      limit: budget.amountLimit,
      used: used,
      elapsedDays: elapsed,
      totalDays: totalDays,
    );
  }

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
