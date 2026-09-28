import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/validator.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class TransactionController extends GetxController {
  TransactionController(this._repository);

  final TransactionRepository _repository;
  final range = Rxn<DateRange>();
  final state = const ResourceState<List<TransactionModel>>.idle().obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({DateRange? selectedRange}) async {
    if (selectedRange != null) range.value = selectedRange;
    state.value = const ResourceState.loading();
    try {
      final transactions = await _repository.getAll(range: range.value);
      state.value = transactions.isEmpty ? const ResourceState.empty() : ResourceState.success(transactions);
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat transaksi.');
    }
  }

  Future<bool> save(TransactionModel transaction) async {
    final titleError = requiredText(transaction.title, fieldName: 'Nama transaksi');
    final amountError = positiveAmount(transaction.amount);
    if (titleError != null || amountError != null || transaction.categoryId <= 0) {
      state.value = ResourceState.error(titleError ?? amountError ?? 'Kategori transaksi wajib dipilih.');
      return false;
    }
    try {
      if (transaction.id == null) {
        await _repository.insert(transaction);
      } else {
        await _repository.update(transaction);
      }
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menyimpan transaksi.');
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menghapus transaksi.');
      return false;
    }
  }

  Future<bool> duplicate(TransactionModel transaction) async {
    try {
      await _repository.insert(TransactionModel(
        type: transaction.type,
        title: transaction.title,
        amount: transaction.amount,
        currency: transaction.currency,
        transactionDate: transaction.transactionDate,
        categoryId: transaction.categoryId,
        merchantOrSource: transaction.merchantOrSource,
        paymentMethod: transaction.paymentMethod,
        note: transaction.note,
        receiptPath: transaction.receiptPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menduplikasi transaksi.');
      return false;
    }
  }
}
