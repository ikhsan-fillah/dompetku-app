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
  ) => transactions
      .where((transaction) => range.contains(transaction.transactionDate))
      .toList();

  DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  int totalForType(
    Iterable<TransactionModel> transactions,
    TransactionType type,
    DateRange range,
  ) => _within(transactions, range)
      .where((transaction) => transaction.type == type)
      .fold(0, (total, transaction) => total + transaction.amount);

  DashboardSummaryModel summary(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) {
    final income = totalForType(transactions, TransactionType.income, range);
    final expense = totalForType(transactions, TransactionType.expense, range);
    return DashboardSummaryModel(
      income: income,
      expense: expense,
      balance: income - expense,
    );
  }

  Map<int, int> categoryTotals(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) {
    final totals = <int, int>{};
    for (final transaction in _within(
      transactions,
      range,
    ).where((item) => item.type == TransactionType.expense)) {
      totals.update(
        transaction.categoryId,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  List<SpendingTrendPoint> dailyExpenses(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) {
    final amounts = <DateTime, int>{};
    for (final transaction in _within(
      transactions,
      range,
    ).where((item) => item.type == TransactionType.expense)) {
      final day = _day(transaction.transactionDate);
      amounts.update(
        day,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return amounts.entries
        .map(
          (entry) => SpendingTrendPoint(date: entry.key, amount: entry.value),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double monthlyEfficiency({
    required int spent,
    required int monthlyLimit,
    required DateTime day,
  }) {
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
    final previous = totalForType(
      transactions,
      TransactionType.expense,
      range.previousEquivalentPeriod,
    );
    if (previous == 0) return current == 0 ? 0 : 1;
    return (current - previous) / previous;
  }

  /// Rata-rata pengeluaran harian pada rentang (total dibagi jumlah hari).
  /// Hari tanpa transaksi tetap dihitung.
  double dailyAverage(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) {
    final total = totalForType(transactions, TransactionType.expense, range);
    return range.dayCount == 0 ? 0 : total / range.dayCount;
  }

  /// Hari dengan total pengeluaran terbesar pada rentang.
  DateTime? highestSpendingDay(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) {
    final daily = dailyExpenses(transactions, range);
    if (daily.isEmpty) return null;
    return daily.reduce((a, b) => a.amount >= b.amount ? a : b).date;
  }

  /// Total pengeluaran pada [day].
  int expenseOnDay(Iterable<TransactionModel> transactions, DateTime day) {
    return _within(transactions, DateRange(start: day, end: day))
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  /// Nama merchant yang paling sering dipakai transaksi (judul, bukan kategori).
  /// Mengembalikan null bila tidak ada transaksi bergaya merchant.
  MapEntry<String, int>? topMerchant(
    Iterable<TransactionModel> transactions,
    DateRange range,
  ) {
    final counts = <String, int>{};
    for (final transaction in _within(transactions, range)) {
      final merchant = transaction.merchantOrSource;
      final name = (merchant == null || merchant.trim().isEmpty)
          ? transaction.title
          : merchant.trim();
      if (name.isEmpty) continue;
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }
}
