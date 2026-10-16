import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/draft_model.dart';
import '../repositories/draft_repository.dart';

class DraftController extends GetxController {
  DraftController(this._drafts, this._transactions);

  final DraftRepository _drafts;
  final TransactionRepository _transactions;
  final state = const ResourceState<List<DraftModel>>.idle().obs;
  final error = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = const ResourceState.loading();
    try {
      final items = await _drafts.getPending();
      state.value = items.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(items);
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat drafts.');
    }
  }

  /// Membuat transaksi dari draft, lalu menandai draft `confirmed`.
  Future<bool> confirm(DraftModel draft) async {
    final id = draft.id;
    final categoryId = draft.categoryId;
    if (id == null) return false;
    if (categoryId == null) {
      error.value = 'Choose a category before confirming.';
      return false;
    }
    error.value = null;
    try {
      await _transactions.insert(_toTransaction(draft, categoryId));
      await _drafts.setStatus(id, DraftStatus.confirmed);
      await _afterChange();
      return true;
    } catch (_) {
      error.value = 'Failed to confirm. Try again.';
      return false;
    }
  }

  /// Ubah nominal dan nama, lalu konfirmasi. Draft ikut dikonfirmasi.
  Future<bool> editAndConfirm(
    DraftModel draft, {
    required int amount,
    required String merchant,
  }) async {
    final updated = draft.copyWith(amount: amount, merchant: merchant);
    try {
      await _drafts.update(updated);
    } catch (_) {
      error.value = 'Failed to save changes.';
      return false;
    }
    return confirm(updated);
  }

  Future<void> confirmAll() async {
    final current = state.value.data ?? const <DraftModel>[];
    for (final draft in current) {
      await confirm(draft);
    }
  }

  /// Baris tidak dihapus, supaya dedupe_key mencegah deteksi ulang.
  Future<bool> dismiss(DraftModel draft) async {
    final id = draft.id;
    if (id == null) return false;
    try {
      await _drafts.setStatus(id, DraftStatus.dismissed);
      await _afterChange();
      return true;
    } catch (_) {
      error.value = 'Failed to dismiss. Try again.';
      return false;
    }
  }

  Future<void> _afterChange() async {
    if (Get.isRegistered<DataRefreshService>()) {
      Get.find<DataRefreshService>().bump();
    }
    await load();
  }

  TransactionModel _toTransaction(DraftModel draft, int categoryId) {
    final now = DateTime.now();
    final merchant = draft.merchant?.trim();
    return TransactionModel(
      type: draft.kind,
      title: (merchant == null || merchant.isEmpty) ? draft.source : merchant,
      amount: draft.amount,
      transactionDate: draft.detectedAt.toLocal(),
      categoryId: categoryId,
      merchantOrSource: merchant ?? draft.source,
      createdAt: now,
      updatedAt: now,
    );
  }
}
