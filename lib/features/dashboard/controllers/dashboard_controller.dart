import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../budget/models/budget_model.dart';
import '../../budget/repositories/budget_repository.dart';
import '../../category/repositories/category_repository.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/budget_progress_model.dart';
import '../models/dashboard_summary_model.dart';
import '../models/dashboard_view_models.dart';
import '../models/expense_slice.dart';
import '../models/spending_trend_point.dart';
import '../services/dashboard_insights_service.dart';
import '../services/expense_breakdown_service.dart';
import '../services/financial_calculation_service.dart';

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.trend,
    required this.previousPeriodExpenseChange,
    required this.expenses,
    this.trendBuckets = const [],
    this.budget,
    this.favorites = const [],
    this.recent = const [],
    this.insight,
  });

  final DashboardSummaryModel summary;
  final List<SpendingTrendPoint> trend;
  final double previousPeriodExpenseChange;
  final List<ExpenseSlice> expenses;
  final List<TrendBucket> trendBuckets;
  final BudgetProgressModel? budget;
  final List<CategoryCardData> favorites;
  final List<RecentTransactionItem> recent;
  final DashboardInsight? insight;
}

class DashboardController extends GetxController {
  DashboardController(
    this._transactions,
    this._calculations,
    this._categories, {
    BudgetRepository? budgets,
  }) : _budgets = budgets;

  final TransactionRepository _transactions;
  final FinancialCalculationService _calculations;
  final CategoryRepository _categories;
  final BudgetRepository? _budgets;
  final _breakdown = const ExpenseBreakdownService();
  final _insights = const DashboardInsightsService();
  final range = DateRange.fromPreset(DateRangePreset.month).obs;
  final preset = DateRangePreset.month.obs;
  final state = const ResourceState<DashboardData>.idle().obs;

  Worker? _refreshWorker;
  int _requestId = 0;

  BudgetRepository? get _budgetRepository =>
      _budgets ??
      (Get.isRegistered<BudgetRepository>() ? Get.find<BudgetRepository>() : null);

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<DataRefreshService>()) {
      _refreshWorker = ever<int>(
        Get.find<DataRefreshService>().version,
        (_) => refreshDashboard(silent: true),
      );
    }
    refreshDashboard();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    super.onClose();
  }

  /// Memilih rentang cepat (hari ini, minggu, bulan, ...). Rentang kustom lewat [setRange].
  Future<void> setPreset(DateRangePreset value) async {
    if (value == DateRangePreset.custom) return;
    preset.value = value;
    range.value = DateRange.fromPreset(value);
    await refreshDashboard();
  }

  Future<void> setRange(DateRange value) async {
    preset.value = DateRangePreset.custom;
    range.value = value;
    await refreshDashboard();
  }

  /// Memuat ulang ringkasan. Bila [silent] true dan data sudah tampil,
  /// layar tidak berkedip ke keadaan memuat.
  Future<void> refreshDashboard({bool silent = false}) async {
    final requestId = ++_requestId;
    if (!silent || state.value.status != ResourceStatus.success) {
      state.value = const ResourceState.loading();
    }
    try {
      final selected = range.value;
      final transactions = await _transactions.getAll();
      final current = transactions
          .where((item) => selected.contains(item.transactionDate))
          .toList();
      if (current.isEmpty) {
        if (requestId != _requestId) return;
        state.value = const ResourceState.empty();
        return;
      }
      final categories = await _categories.getAll(includeArchived: true);
      final budgetRepository = _budgetRepository;
      final budgets = budgetRepository == null
          ? <BudgetModel>[]
          : await budgetRepository.getAll();
      if (requestId != _requestId) return;

      final totals = _calculations.categoryTotals(transactions, selected);
      final previousTotals = _calculations.categoryTotals(
        transactions,
        selected.previousEquivalentPeriod,
      );
      final trend = _calculations.dailyExpenses(transactions, selected);
      final activeBudget = _calculations.activeOverallBudget(budgets);

      state.value = ResourceState.success(
        DashboardData(
          summary: _calculations.summary(transactions, selected),
          trend: trend,
          trendBuckets: _insights.trendBuckets(points: trend, range: selected),
          previousPeriodExpenseChange: _calculations
              .previousPeriodExpenseChange(transactions, selected),
          expenses: _breakdown.build(totals, categories),
          budget: activeBudget == null
              ? null
              : _calculations.budgetProgress(transactions, activeBudget),
          favorites: _insights.favoriteCards(
            totals: totals,
            categories: categories,
          ),
          recent: _insights.recentTransactions(
            transactions: transactions,
            categories: categories,
            range: selected,
          ),
          insight: _insights.spendingInsight(
            current: totals,
            previous: previousTotals,
            categories: categories,
          ),
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      state.value = const ResourceState.error(
        'Gagal memuat ringkasan dashboard.',
      );
    }
  }
}
