import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../dashboard/models/dashboard_summary_model.dart';
import '../../dashboard/services/financial_calculation_service.dart';
import '../../transaction/repositories/transaction_repository.dart';

class ReportController extends GetxController {
  ReportController(this._transactions, this._calculations);

  final TransactionRepository _transactions;
  final FinancialCalculationService _calculations;
  final range = DateRange.fromPreset(DateRangePreset.month).obs;
  final state = const ResourceState<DashboardSummaryModel>.idle().obs;

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
      state.value = currentTransactions.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(
              _calculations.summary(transactions, selectedRange),
            );
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat laporan.');
    }
  }
}
