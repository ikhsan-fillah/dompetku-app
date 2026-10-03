import '../../../core/utils/date_range.dart';
import '../../budget/models/budget_model.dart';
import '../../transaction/models/transaction_model.dart';
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

  int get budgetUsed => total;
  int get budgetRemaining => (budget?.amountLimit ?? 0) - total;
  double get budgetPercent => budget == null || budget!.amountLimit == 0
      ? 0
      : total * 100 / budget!.amountLimit;
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
    final category = categories.cast<CategoryModel?>().firstWhere(
      (item) => item?.id == categoryId,
      orElse: () => null,
    );
    final current = transactions.where(
      (item) =>
          item.categoryId == categoryId &&
          item.type.name == 'expense' &&
          range.contains(item.transactionDate),
    ).toList()
      ..sort((a, b) {
        final date = b.transactionDate.compareTo(a.transactionDate);
        return date != 0 ? date : (b.id ?? 0).compareTo(a.id ?? 0);
      });
    final previousRange = range.previousEquivalentPeriod;
    final previousTotal = transactions
        .where(
          (item) =>
              item.categoryId == categoryId &&
              item.type.name == 'expense' &&
              previousRange.contains(item.transactionDate),
        )
        .fold<int>(0, (sum, item) => sum + item.amount);
    final total = current.fold<int>(0, (sum, item) => sum + item.amount);
    final periodExpenses = transactions
        .where(
          (item) =>
              item.type.name == 'expense' &&
              range.contains(item.transactionDate),
        )
        .fold<int>(0, (sum, item) => sum + item.amount);
    final activeBudget = budgets.where((item) {
      return !item.isArchived &&
          item.categoryId == categoryId &&
          !item.endDate.isBefore(range.start) &&
          !item.startDate.isAfter(range.end);
    }).firstOrNull;
    return CategoryDetailData(
      category: category,
      transactions: current,
      total: total,
      transactionCount: current.length,
      average: current.isEmpty ? 0 : total ~/ current.length,
      percentOfExpenses:
          periodExpenses == 0 ? 0 : total * 100 / periodExpenses,
      previousTotal: previousTotal,
      changePercent: previousTotal == 0
          ? (total == 0 ? 0 : 100)
          : (total - previousTotal) * 100 / previousTotal,
      budget: activeBudget,
    );
  }
}