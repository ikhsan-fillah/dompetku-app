import '../../transaction/models/transaction_model.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';
import '../../budget/models/budget_model.dart';
import '../models/category_model.dart';

class CategoryDetailData {
  const CategoryDetailData({
    required this.category,
    required this.transactions,
    required this.total,
    required this.transactionCount,
    required this.average,
    required this.percentOfExpenses,
    required this.previousTotal,
    required this.changePercent,
    this.budget,
  });

  final CategoryModel? category;
  final List<TransactionModel> transactions;
  final int total;
  final int transactionCount;
  final int average;
  final double percentOfExpenses;
  final int previousTotal;
  final double changePercent;
  final BudgetModel? budget;
}

enum CategoryTransactionSort { newest, oldest }

class TransactionDayGroup {
  const TransactionDayGroup({required this.date, required this.transactions});

  final DateTime date;
  final List<TransactionModel> transactions;
}

class CategoryDetailService {
  const CategoryDetailService();

  CategoryDetailData build({
    required int categoryId,
    required DateRange range,
    required Iterable<TransactionModel> transactions,
    required List<CategoryModel> categories,
    Iterable<BudgetModel> budgets = const [],
  }) {
    final current = transactions.where((item) =>
        item.categoryId == categoryId && range.contains(item.transactionDate));
    final list = current.toList();
    final total = list.fold<int>(0, (sum, item) => sum + item.amount);
    final previousRange = range.previousEquivalentPeriod;
    final previousTotal = transactions
      .where((item) => item.categoryId == categoryId &&
        previousRange.contains(item.transactionDate))
      .fold<int>(0, (sum, item) => sum + item.amount);
    final periodExpenses = transactions
      .where((item) => item.type == TransactionType.expense &&
        range.contains(item.transactionDate))
      .fold<int>(0, (sum, item) => sum + item.amount);
    return CategoryDetailData(
      category: categories.where((item) => item.id == categoryId).firstOrNull,
      transactions: list,
      total: total,
      transactionCount: list.length,
      average: list.isEmpty ? 0 : total ~/ list.length,
        percentOfExpenses: periodExpenses == 0 ? 0 : total * 100 / periodExpenses,
        previousTotal: previousTotal,
        changePercent: previousTotal == 0
          ? (total == 0 ? 0 : 100)
          : (total - previousTotal) * 100 / previousTotal,
      budget: budgets.where((item) => item.categoryId == categoryId).firstOrNull,
    );
  }

  List<TransactionDayGroup> group(
    Iterable<TransactionModel> transactions,
    CategoryTransactionSort sort,
  ) {
    final sorted = transactions.toList()
      ..sort((a, b) {
        var result = a.transactionDate.compareTo(b.transactionDate);
        if (sort == CategoryTransactionSort.newest) result = -result;
        if (result == 0) {
          result = a.createdAt.compareTo(b.createdAt);
          if (sort == CategoryTransactionSort.newest) result = -result;
        }
        if (result == 0) {
          result = (a.id ?? 0).compareTo(b.id ?? 0);
          if (sort == CategoryTransactionSort.newest) result = -result;
        }
        return result;
      });
    final groups = <DateTime, List<TransactionModel>>{};
    for (final transaction in sorted) {
      final local = transaction.transactionDate.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(day, () => []).add(transaction);
    }
    return [
      for (final entry in groups.entries)
        TransactionDayGroup(date: entry.key, transactions: entry.value),
    ];
  }
}
