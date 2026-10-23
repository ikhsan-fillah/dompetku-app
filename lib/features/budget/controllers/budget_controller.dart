import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/budget_model.dart';
import '../models/budget_view_model.dart';
import '../repositories/budget_repository.dart';
import '../services/budget_list_service.dart';

class BudgetController extends GetxController {
  BudgetController(this._repository, {TransactionRepository? transactions})
    : _transactions = transactions;

  final BudgetRepository _repository;
  final TransactionRepository? _transactions;
  final state = const ResourceState<List<BudgetViewModel>>.idle().obs;
  final archived = const ResourceState<List<BudgetViewModel>>.idle().obs;
  final sort = BudgetSort.persentaseTerpakaiTertinggi.obs;
  final _listService = const BudgetListService();

  List<BudgetViewModel> get visibleItems => _listService.sort(
    state.value.data ?? const <BudgetViewModel>[],
    sort.value,
  );

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

  void setSort(BudgetSort value) => sort.value = value;

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
      final transactions = await _loadTransactions(budgets);
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
      state.value = ResourceState.error('Gagal memuat anggaran.'.tr);
    }
  }

  Future<void> loadArchived() async {
    if (archived.value.status != ResourceStatus.success) {
      archived.value = const ResourceState.loading();
    }
    try {
      final all = await _repository.getAll(includeArchived: true);
      final budgets = all.where((budget) => budget.isArchived).toList();
      final transactions = await _loadTransactions(budgets);
      final items = [
        for (final budget in budgets)
          BudgetViewModel(budget: budget, used: _usedFor(budget, transactions)),
      ];
      archived.value = items.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(items);
    } catch (_) {
      archived.value = ResourceState.error(
        'Gagal memuat anggaran terarsip.'.tr,
      );
    }
  }

  /// Hanya transaksi dalam rentang gabungan anggaran yang dibaca, bukan semua.
  Future<List<TransactionModel>> _loadTransactions(
    List<BudgetModel> budgets,
  ) async {
    final repository = _transactionRepository;
    if (repository == null || budgets.isEmpty) return const [];
    var start = budgets.first.startDate;
    var end = budgets.first.endDate;
    for (final budget in budgets) {
      if (budget.startDate.isBefore(start)) start = budget.startDate;
      if (budget.endDate.isAfter(end)) end = budget.endDate;
    }
    return repository.getAll(
      range: DateRange(start: start, end: end),
    );
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
      state.value = ResourceState.error('Gagal mengarsipkan anggaran.'.tr);
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
      archived.value = ResourceState.error('Gagal memulihkan anggaran.'.tr);
      return false;
    }
  }
}
