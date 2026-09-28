import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/validator.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';

class BudgetController extends GetxController {
  BudgetController(this._repository);

  final BudgetRepository _repository;
  final state = const ResourceState<List<BudgetModel>>.idle().obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = const ResourceState.loading();
    try {
      final budgets = await _repository.getAll();
      state.value = budgets.isEmpty ? const ResourceState.empty() : ResourceState.success(budgets);
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat anggaran.');
    }
  }

  Future<bool> save(BudgetModel budget) async {
    final nameError = requiredText(budget.name, fieldName: 'Nama anggaran');
    final amountError = positiveAmount(budget.amountLimit);
    if (nameError != null || amountError != null || budget.startDate.isAfter(budget.endDate)) {
      state.value = ResourceState.error(
        nameError ?? amountError ?? 'Tanggal mulai tidak boleh setelah tanggal selesai.',
      );
      return false;
    }
    try {
      if (budget.id == null) {
        await _repository.insert(budget);
      } else {
        await _repository.update(budget);
      }
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menyimpan anggaran.');
      return false;
    }
  }

  Future<bool> archive(int id) async {
    try {
      await _repository.archive(id);
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal mengarsipkan anggaran.');
      return false;
    }
  }
}
