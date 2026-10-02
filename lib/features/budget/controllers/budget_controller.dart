import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/budget_model.dart';
import '../models/budget_view_model.dart';
import '../repositories/budget_repository.dart';

class BudgetController extends GetxController {
  BudgetController(this._repository, {TransactionRepository? transactions})
    : _transactions = transactions;

  final BudgetRepository _repository;
  final TransactionRepository? _transactions;
  final state = const ResourceState<List<BudgetViewModel>>.idle().obs;
  final archived = const ResourceState<List<BudgetViewModel>>.idle().obs;

  Worker? _refreshWorker;
  int _requestId = 0;

  TransactionRepository? get _transactionRepository =>
      _transactions ??
      (Get.isRegistered<TransactionRepository>()
          ? Get.find<TransactionRepository>()
          : null);

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<DataRefreshService>()) {
      _refreshWorker = ever<int>(
        Get.find<DataRefreshService>().version,
        (_) => load(silent: true),
      );
    }
    load();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    super.onClose();
  }

  Future<void> load({bool silent = false}) async {
    final requestId = ++_requestId;
    if (!silent || state.value.status != ResourceStatus.success) {
      state.value = const ResourceState.loading();
    }
    if (archived.value.status == ResourceStatus.success) {
      await loadArchived();
    }
    try {
      final budgets = await _repository.getAll();
      final transactionRepository = _transactionRepository;
      final transactions = transactionRepository == null
          ? const <TransactionModel>[]
          : await transactionRepository.getAll();
      if (requestId != _requestId) return;
      final items = [
        for (final budget in budgets)
          BudgetViewModel(budget: budget, used: _usedFor(budget, transactions)),
      ];
      state.value = items.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(items);
    } catch (_) {
      if (requestId != _requestId) return;
      state.value = const ResourceState.error('Gagal memuat anggaran.');
    }
  }

  Future<void> loadArchived() async {
    try {
      final budgets = await _repository.getAll(includeArchived: true);
      final transactionRepository = _transactionRepository;
      final transactions = transactionRepository == null
          ? const <TransactionModel>[]
          : await transactionRepository.getAll();
      final items = [
        for (final budget in budgets)
          BudgetViewModel(budget: budget, used: _usedFor(budget, transactions)),
      ];
      archived.value = items.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(items);
    } catch (_) {
      archived.value = const ResourceState.error(
        'Gagal memuat anggaran terarsip.',
      );
    }
  }

  int _usedFor(BudgetModel budget, List<TransactionModel> transactions) {
    final range = DateRange(start: budget.startDate, end: budget.endDate);
    var total = 0;
    for (final transaction in transactions) {
      if (transaction.type.name != 'expense') continue;
      if (!range.contains(transaction.transactionDate)) continue;
      if (budget.categoryId != null &&
          transaction.categoryId != budget.categoryId) {
        continue;
      }
      total += transaction.amount;
    }
    return total;
  }

  Future<bool> archive(int id) async {
    try {
      await _repository.archive(id);
      if (Get.isRegistered<DataRefreshService>()) {
        Get.find<DataRefreshService>().bump();
      } else {
        await load(silent: true);
      }
      return true;
    } catch (_) {
      state.value = const ResourceState.error('Gagal mengarsipkan anggaran.');
      return false;
    }
  }

  /// Memulihkan anggaran terarsip kembali ke daftar aktif.
  Future<bool> restore(int id) async {
    try {
      await _repository.restore(id);
      await load(silent: true);
      await loadArchived();
      return true;
    } catch (_) {
      archived.value = const ResourceState.error('Gagal memulihkan anggaran.');
      return false;
    }
  }
}
