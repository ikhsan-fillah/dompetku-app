import 'package:get/get.dart';

import '../models/recurring_rule.dart';
import 'recurring_controller.dart';

/// Validasi dan simpan aturan recurring, baru maupun yang diubah. Tanpa UI.
class RecurringFormController extends GetxController {
  RecurringFormController(this._store, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final RecurringStore _store;
  final DateTime Function() _now;

  final name = ''.obs;
  final amountDigits = ''.obs;
  final categoryId = Rxn<int>();
  final type = RecurringType.expense.obs;
  final frequency = RecurringFrequency.monthly.obs;
  final mode = RecurringMode.ask.obs;
  final amountVaries = false.obs;
  final startDate = Rxn<DateTime>();
  final saving = false.obs;
  final error = Rxn<String>();
  RecurringRule? _editing;

  bool get isEditing => _editing != null;

  /// Mengosongkan isian untuk transaksi berulang baru.
  void startNew() {
    _editing = null;
    name.value = '';
    amountDigits.value = '';
    categoryId.value = null;
    type.value = RecurringType.expense;
    frequency.value = RecurringFrequency.monthly;
    mode.value = RecurringMode.ask;
    amountVaries.value = false;
    startDate.value = null;
    error.value = null;
    saving.value = false;
  }

  /// Mengisi form dengan aturan yang akan diubah.
  void startEdit(RecurringRule rule) {
    _editing = rule;
    name.value = rule.name;
    amountDigits.value = '${rule.amount}';
    categoryId.value = rule.categoryId;
    type.value = rule.type;
    frequency.value = rule.frequency;
    mode.value = rule.mode;
    startDate.value = rule.startDate;
    error.value = null;
    saving.value = false;
  }

  Future<bool> save() async {
    if (saving.value) return false;
    error.value = null;
    final trimmed = name.value.trim();
    if (trimmed.isEmpty) {
      error.value = 'Nama wajib diisi.'.tr;
      return false;
    }
    final amount = int.tryParse(amountDigits.value) ?? 0;
    if (amount <= 0) {
      error.value = 'Nominal harus lebih dari nol.'.tr;
      return false;
    }
    final category = categoryId.value;
    if (category == null) {
      error.value = 'Pilih kategori.'.tr;
      return false;
    }

    final picked = startDate.value ?? _now();
    final start = DateTime(picked.year, picked.month, picked.day);
    final isMonthly = frequency.value == RecurringFrequency.monthly;
    final isWeekly = frequency.value == RecurringFrequency.weekly;

    saving.value = true;
    try {
      final editing = _editing;
      final now = DateTime.now().toUtc();
      final rule = RecurringRule(
        id: editing?.id,
        name: trimmed,
        type: type.value,
        categoryId: category,
        amount: amount,
        frequency: frequency.value,
        dayOfMonth: isMonthly ? start.day : null,
        weekday: isWeekly ? start.weekday : null,
        startDate: start,
        mode: mode.value,
        isActive: editing?.isActive ?? true,
        lastGeneratedOn: editing?.lastGeneratedOn,
        createdAt: editing?.createdAt ?? now,
        updatedAt: now,
      );
      if (editing == null) {
        await _store.insert(rule);
      } else {
        await _store.update(rule);
      }
      return true;
    } catch (_) {
      error.value = 'Gagal menyimpan. Coba lagi.'.tr;
      return false;
    } finally {
      saving.value = false;
    }
  }
}
