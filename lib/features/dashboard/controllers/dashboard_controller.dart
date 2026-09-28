import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/dashboard_summary_model.dart';
import '../models/spending_trend_point.dart';
import '../services/financial_calculation_service.dart';

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.trend,
    required this.previousPeriodExpenseChange,
  });

  final DashboardSummaryModel summary;
  final List<SpendingTrendPoint> trend;
  final double previousPeriodExpenseChange;
}

class DashboardController extends GetxController {
  DashboardController(this._transactions, this._calculations);

  final TransactionRepository _transactions;
  final FinancialCalculationService _calculations;
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
      // Load all records because the previous equivalent period can precede
      // the selected range. Calculations filter their own inclusive ranges.
      final transactions = await _transactions.getAll();
      final currentTransactions = transactions
          .where(
            (transaction) => range.value.contains(transaction.transactionDate),
          )
          .toList();
      if (currentTransactions.isEmpty) {
        state.value = const ResourceState.empty();
        return;
      }
      state.value = ResourceState.success(
        DashboardData(
          summary: _calculations.summary(transactions, range.value),
          trend: _calculations.dailyExpenses(transactions, range.value),
          previousPeriodExpenseChange: _calculations
              .previousPeriodExpenseChange(transactions, range.value),
        ),
      );
    } catch (_) {
      state.value = const ResourceState.error(
        'Gagal memuat ringkasan dashboard.',
      );
    }
  }
}
