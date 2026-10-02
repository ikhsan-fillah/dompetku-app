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

  /// Data contoh untuk pengguna yang belum pernah mencatat transaksi,
  /// agar Beranda tetap menampilkan seluruh kartu dan grafik.
  factory DashboardData.preview({DateTime? now}) {
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    const dailyAmounts = [120000, 85000, 0, 240000, 60000, 310000, 150000];
    final dates = [
      for (var i = 0; i < dailyAmounts.length; i++)
        DateTime(day.year, day.month, day.day - (dailyAmounts.length - 1 - i)),
    ];
    const rawExpenses = <(int, String, int, int)>[
      (1, 'Makan & Minum', 0xFFE57373, 1300000),
      (2, 'Transportasi', 0xFF64B5F6, 800000),
      (3, 'Belanja', 0xFFBA68C8, 600000),
      (4, 'Tagihan', 0xFFFFB74D, 550000),
    ];
    const icons = ['restaurant', 'directions_car', 'shopping_bag', 'receipt_long'];
    final totalExpense = rawExpenses.fold<int>(0, (sum, item) => sum + item.$4);
    const income = 5000000;
    final daysInMonth = DateTime(day.year, day.month + 1, 0).day;

    return DashboardData(
      summary: DashboardSummaryModel(
        income: income,
        expense: totalExpense,
        balance: income - totalExpense,
      ),
      trend: [
        for (var i = 0; i < dailyAmounts.length; i++)
          SpendingTrendPoint(date: dates[i], amount: dailyAmounts[i]),
      ],
      trendBuckets: [
        for (var i = 0; i < dailyAmounts.length; i++)
          TrendBucket(
            label: '${dates[i].day}',
            start: dates[i],
            end: dates[i],
            amount: dailyAmounts[i],
          ),
      ],
      previousPeriodExpenseChange: 0.12,
      expenses: [
        for (final item in rawExpenses)
          ExpenseSlice(
            categoryId: item.$1,
            name: item.$2,
            colorValue: item.$3,
            amount: item.$4,
            percent: item.$4 * 100 / totalExpense,
          ),
      ],
      budget: BudgetProgressModel(
        name: 'Contoh anggaran',
        limit: 3000000,
        used: 1850000,
        elapsedDays: day.day,
        totalDays: daysInMonth,
      ),
      favorites: [
        for (var i = 0; i < rawExpenses.length; i++)
          CategoryCardData(
            categoryId: rawExpenses[i].$1,
            name: rawExpenses[i].$2,
            iconKey: icons[i],
            colorValue: rawExpenses[i].$3,
            amount: rawExpenses[i].$4,
            sharePercent: rawExpenses[i].$4 * 100 / totalExpense,
          ),
      ],
      recent: [
        RecentTransactionItem(
          id: -1,
          title: 'Makan siang',
          categoryName: 'Makan & Minum',
          iconKey: 'restaurant',
          colorValue: 0xFFE57373,
          amount: 35000,
          isIncome: false,
          date: day,
        ),
        RecentTransactionItem(
          id: -2,
          title: 'Isi bensin',
          categoryName: 'Transportasi',
          iconKey: 'directions_car',
          colorValue: 0xFF64B5F6,
          amount: 50000,
          isIncome: false,
          date: dates[dates.length - 2],
        ),
        RecentTransactionItem(
          id: -3,
          title: 'Gaji bulanan',
          categoryName: 'Gaji',
          iconKey: 'payments',
          colorValue: 0xFF43A047,
          amount: 5000000,
          isIncome: true,
          date: dates[dates.length - 4],
        ),
      ],
      insight: const DashboardInsight(
        message: 'Makan & Minum naik 12% dibanding periode sebelumnya',
      ),
    );
  }

  /// Data nol untuk periode tanpa transaksi (pengguna sudah punya transaksi lain).
  factory DashboardData.emptyPeriod() => const DashboardData(
    summary: DashboardSummaryModel(income: 0, expense: 0, balance: 0),
    trend: <SpendingTrendPoint>[],
    previousPeriodExpenseChange: 0,
    expenses: <ExpenseSlice>[],
  );

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

  /// True bila pengguna pernah mencatat setidaknya satu transaksi (periode apa pun).
  final hasAnyTransactions = false.obs;

  Worker? _refreshWorker;
  int _requestId = 0;

  BudgetRepository? get _budgetRepository =>
      _budgets ??
      (Get.isRegistered<BudgetRepository>()
          ? Get.find<BudgetRepository>()
          : null);

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
      if (requestId != _requestId) return;
      hasAnyTransactions.value = transactions.isNotEmpty;
      final current = transactions
          .where((item) => selected.contains(item.transactionDate))
          .toList();
      if (current.isEmpty) {
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
