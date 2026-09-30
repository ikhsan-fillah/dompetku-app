import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../category/repositories/category_repository.dart';
import '../../dashboard/models/dashboard_summary_model.dart';
import '../../dashboard/services/financial_calculation_service.dart';
import '../../transaction/repositories/transaction_repository.dart';

class ReportData {
  const ReportData({
    required this.summary,
    required this.expensesByCategory,
    required this.expenseChange,
  });

  final DashboardSummaryModel summary;
  final List<ReportCategoryTotal> expensesByCategory;
  final double expenseChange;
}

class ReportCategoryTotal {
  const ReportCategoryTotal({
    required this.categoryId,
    required this.name,
    required this.colorValue,
    required this.amount,
  });

  final int categoryId;
  final String name;
  final int colorValue;
  final int amount;
}

class ReportController extends GetxController {
  ReportController(this._transactions, this._categories, this._calculations);

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final FinancialCalculationService _calculations;
  final range = DateRange.fromPreset(DateRangePreset.month).obs;
  final state = const ResourceState<ReportData>.idle().obs;

  Future<void> load(DateRange selectedRange) async {
    range.value = selectedRange;
    state.value = const ResourceState.loading();
    try {
      final transactions = await _transactions.getAll();
      final currentTransactions = transactions
          .where(
            (transaction) =>
                selectedRange.contains(transaction.transactionDate),
          )
          .toList();
      if (currentTransactions.isEmpty) {
        state.value = const ResourceState.empty();
        return;
      }

      final categories = await _categories.getAll(includeArchived: true);
      final categoriesById = {
        for (final category in categories)
          if (category.id != null) category.id!: category,
      };
      final totals = _calculations.categoryTotals(transactions, selectedRange);
      final expensesByCategory = totals.entries
          .map((entry) {
            final category = categoriesById[entry.key];
            return ReportCategoryTotal(
              categoryId: entry.key,
              name: category?.name ?? 'Kategori diarsipkan',
              colorValue: category?.colorValue ?? 0xFF64748B,
              amount: entry.value,
            );
          })
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      state.value = ResourceState.success(
        ReportData(
          summary: _calculations.summary(transactions, selectedRange),
          expensesByCategory: expensesByCategory,
          expenseChange: _calculations.previousPeriodExpenseChange(
            transactions,
            selectedRange,
          ),
        ),
      );
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat laporan.');
    }
  }
}
