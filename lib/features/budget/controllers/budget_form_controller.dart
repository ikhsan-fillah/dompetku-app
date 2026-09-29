import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';

class BudgetFormController extends GetxController {
  BudgetFormController(this._budgets, this._categories);

  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final name = ''.obs;
  final amountDigits = ''.obs;
  final categoryId = Rxn<int>();
  final startDate = _day(DateTime.now()).obs;
  final endDate = _monthEnd(DateTime.now()).obs;
  final availableCategories = <CategoryModel>[].obs;
  final saving = false.obs;
  final error = Rxn<String>();
  BudgetModel? _editing;

  bool get isEditing => _editing != null;
  bool get isOverall => categoryId.value == null;
  int? get amount => int.tryParse(amountDigits.value);

  static DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime _monthEnd(DateTime value) =>
      DateTime(value.year, value.month + 1, 0);

  Future<void> _loadCategories() async {
    try {
      final all = await _categories.getAll();
      availableCategories.assignAll(
        all.where((item) =>
            !item.isArchived && item.type.name == 'expense' && item.id != null),
      );
    } catch (_) {
      error.value = 'Gagal memuat kategori.';
    }
  }

  Future<void> startNew({DateTime? now}) async {
    final today = _day(now ?? DateTime.now());
    _editing = null;
    name.value = '';
    amountDigits.value = '';
    categoryId.value = null;
    startDate.value = DateTime(today.year, today.month, 1);
    endDate.value = _monthEnd(today);
    error.value = null;
    saving.value = false;
    await _loadCategories();
  }

  Future<void> startEdit(BudgetModel budget) async {
    _editing = budget;
    name.value = budget.name;
    amountDigits.value = budget.amountLimit.toString();
    categoryId.value = budget.categoryId;
    startDate.value = _day(budget.startDate);
    endDate.value = _day(budget.endDate);
    error.value = null;
    saving.value = false;
    await _loadCategories();
  }

  void setDates({DateTime? start, DateTime? end}) {
    if (start != null) startDate.value = _day(start);
    if (end != null) endDate.value = _day(end);
    error.value = null;
  }

  void setOverall(bool value) {
    if (value) categoryId.value = null;
    error.value = null;
  }

  String? _validate() {
    if (name.value.trim().isEmpty) return 'Nama anggaran wajib diisi.';
    if (amount == null || amount! <= 0) {
      return 'Batas anggaran harus lebih dari nol.';
    }
    if (startDate.value.isAfter(endDate.value)) {
      return 'Tanggal mulai tidak boleh setelah tanggal selesai.';
    }
    return null;
  }

  Future<bool> save() async {
    final problem = _validate();
    if (problem != null) {
      error.value = problem;
      return false;
    }
    saving.value = true;
    try {
      final now = DateTime.now();
      final budget = BudgetModel(
        id: _editing?.id,
        name: name.value.trim(),
        amountLimit: amount!,
        categoryId: categoryId.value,
        startDate: startDate.value,
        endDate: endDate.value,
        isArchived: _editing?.isArchived ?? false,
        createdAt: _editing?.createdAt ?? now,
        updatedAt: now,
      );
      if (_editing == null) {
        await _budgets.insert(budget);
      } else {
        await _budgets.update(budget);
      }
      if (Get.isRegistered<DataRefreshService>()) {
        Get.find<DataRefreshService>().bump();
      }
      return true;
    } catch (_) {
      error.value = 'Gagal menyimpan anggaran.';
      return false;
    } finally {
      saving.value = false;
    }
  }
}
