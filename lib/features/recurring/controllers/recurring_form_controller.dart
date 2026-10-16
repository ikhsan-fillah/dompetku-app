import 'package:get/get.dart';

import '../models/recurring_rule.dart';
import 'recurring_controller.dart';

/// Validasi dan simpan aturan recurring baru. Tanpa UI.
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
  final saving = false.obs;
  final error = Rxn<String>();

  Future<bool> save() async {
    if (saving.value) return false;
    error.value = null;
    final trimmed = name.value.trim();
    if (trimmed.isEmpty) {
      error.value = 'Name is required.';
      return false;
    }
    final amount = int.tryParse(amountDigits.value) ?? 0;
    if (amount <= 0) {
      error.value = 'Amount must be more than zero.';
      return false;
    }
    final category = categoryId.value;
    if (category == null) {
      error.value = 'Choose a category.';
      return false;
    }

    final today = _now();
    final start = DateTime(today.year, today.month, today.day);
    final isMonthly = frequency.value == RecurringFrequency.monthly;
    final isWeekly = frequency.value == RecurringFrequency.weekly;

    saving.value = true;
    try {
      await _store.insert(
        RecurringRule(
          name: trimmed,
          type: type.value,
          categoryId: category,
          amount: amount,
          frequency: frequency.value,
          dayOfMonth: isMonthly ? start.day : null,
          weekday: isWeekly ? start.weekday : null,
          startDate: start,
          mode: mode.value,
          isActive: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      return true;
    } catch (_) {
      error.value = 'Failed to save. Try again.';
      return false;
    } finally {
      saving.value = false;
    }
  }
}
