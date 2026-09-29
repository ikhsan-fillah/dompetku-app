import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../../core/utils/amount_input.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

/// State dan aturan form tambah/edit transaksi.
class TransactionFormController extends GetxController {
  TransactionFormController(this._transactions, this._categories);

  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  final type = TransactionType.expense.obs;
  final amountDigits = ''.obs;
  final categoryId = Rxn<int>();
  final paymentMethod = Rxn<PaymentMethod>(PaymentMethod.cash);
  final date = _day(DateTime.now()).obs;
  final title = ''.obs;
  final note = ''.obs;
  final error = Rxn<String>();
  final saving = false.obs;
  final categories = <CategoryModel>[].obs;

  TransactionModel? _editing;

  bool get isEditing => _editing != null;

  int? get amount => AmountInput.parse(amountDigits.value);

  List<CategoryModel> get availableCategories => categories
      .where((c) => c.type == type.value && !c.isArchived)
      .toList();

  static DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  void _reset(TransactionType initialType) {
    _editing = null;
    type.value = initialType;
    amountDigits.value = '';
    categoryId.value = null;
    paymentMethod.value = PaymentMethod.cash;
    date.value = _day(DateTime.now());
    title.value = '';
    note.value = '';
    error.value = null;
    saving.value = false;
  }

  Future<void> _loadCategories() async {
    try {
      categories.assignAll(await _categories.getAll());
    } catch (_) {
      error.value = 'Gagal memuat kategori.';
    }
  }

  void _selectDefaultCategory() {
    final options = availableCategories;
    if (options.isEmpty) {
      categoryId.value = null;
      return;
    }
    final favorite = options.where((c) => c.isFavorite);
    categoryId.value = (favorite.isNotEmpty ? favorite.first : options.first).id;
  }

  Future<void> startNew({
    TransactionType initialType = TransactionType.expense,
  }) async {
    _reset(initialType);
    await _loadCategories();
    _selectDefaultCategory();
  }

  Future<void> startEdit(TransactionModel transaction) async {
    _reset(transaction.type);
    _editing = transaction;
    amountDigits.value = transaction.amount.toString();
    categoryId.value = transaction.categoryId;
    paymentMethod.value = transaction.paymentMethod;
    date.value = _day(transaction.transactionDate);
    title.value = transaction.title;
    note.value = transaction.note ?? '';
    await _loadCategories();
  }

  void setType(TransactionType value) {
    if (type.value == value) return;
    type.value = value;
    error.value = null;
    _selectDefaultCategory();
  }

  void pressKey(String key) {
    amountDigits.value = AmountInput.apply(amountDigits.value, key);
    error.value = null;
  }

  void setDate(DateTime value) {
    final chosen = _day(value);
    final today = _day(DateTime.now());
    date.value = chosen.isAfter(today) ? today : chosen;
    error.value = null;
  }

  String? _validate(int? value) {
    if (value == null || value <= 0) return 'Nominal harus lebih dari nol.';
    if (categoryId.value == null) return 'Pilih kategori dulu.';
    return null;
  }

  DateTime _timestampFor(DateTime chosenDay) {
    final original = _editing?.transactionDate.toLocal();
    final clock = original ?? DateTime.now();
    return DateTime(
      chosenDay.year,
      chosenDay.month,
      chosenDay.day,
      clock.hour,
      clock.minute,
    );
  }

  /// Menyimpan transaksi. Mengembalikan true bila berhasil.
  Future<bool> save() async {
    final value = amount;
    final problem = _validate(value);
    if (problem != null) {
      error.value = problem;
      return false;
    }
    saving.value = true;
    try {
      var categoryName = 'Transaksi';
      for (final category in categories) {
        if (category.id == categoryId.value) categoryName = category.name;
      }
      final titleText = title.value.trim();
      final noteText = note.value.trim();
      final now = DateTime.now();
      final model = TransactionModel(
        id: _editing?.id,
        type: type.value,
        title: titleText.isEmpty ? categoryName : titleText,
        amount: value!,
        transactionDate: _timestampFor(date.value),
        categoryId: categoryId.value!,
        merchantOrSource: _editing?.merchantOrSource,
        paymentMethod: paymentMethod.value,
        note: noteText.isEmpty ? null : noteText,
        receiptPath: _editing?.receiptPath,
        createdAt: _editing?.createdAt ?? now,
        updatedAt: now,
      );
      if (_editing == null) {
        await _transactions.insert(model);
      } else {
        await _transactions.update(model);
      }
      if (Get.isRegistered<DataRefreshService>()) {
        Get.find<DataRefreshService>().bump();
      }
      return true;
    } catch (_) {
      error.value = 'Gagal menyimpan transaksi.';
      return false;
    } finally {
      saving.value = false;
    }
  }
}
