import 'package:get/get.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../category/repositories/category_repository.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/dashboard_summary_model.dart';
import '../models/expense_slice.dart';
import '../models/spending_trend_point.dart';
import '../services/expense_breakdown_service.dart';
import '../services/financial_calculation_service.dart';

class DashboardData {
  const DashboardData({required this.summary, required this.trend, required this.previousPeriodExpenseChange, required this.expenses});
  final DashboardSummaryModel summary;
  final List<SpendingTrendPoint> trend;
  final double previousPeriodExpenseChange;
  final List<ExpenseSlice> expenses;
}

class DashboardController extends GetxController {
  DashboardController(this._transactions, this._calculations, this._categories);
  final TransactionRepository _transactions;
  final FinancialCalculationService _calculations;
  final CategoryRepository _categories;
  final _breakdown = const ExpenseBreakdownService();
  final range = DateRange.fromPreset(DateRangePreset.month).obs;
  final state = const ResourceState<DashboardData>.idle().obs;

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
  }

  Future<void> setRange(DateRange value) async {
    range.value = value;
    await refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    state.value = const ResourceState.loading();
    try {
      final transactions = await _transactions.getAll();
      final current = transactions.where((item) => range.value.contains(item.transactionDate)).toList();
      if (current.isEmpty) {
        state.value = const ResourceState.empty();
        return;
      }
      final categories = await _categories.getAll(includeArchived: true);
      state.value = ResourceState.success(DashboardData(
        summary: _calculations.summary(transactions, range.value),
        trend: _calculations.dailyExpenses(transactions, range.value),
        previousPeriodExpenseChange: _calculations.previousPeriodExpenseChange(transactions, range.value),
        expenses: _breakdown.build(_calculations.categoryTotals(transactions, range.value), categories),
      ));
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat ringkasan dashboard.');
    }
  }
}
