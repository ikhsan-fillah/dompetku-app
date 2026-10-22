import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../models/recurring_rule.dart';

/// Antarmuka penyimpanan yang dipakai controller dan layar (mudah di-test).
abstract interface class RecurringStore {
  Future<List<RecurringRule>> getAll();
  Future<int> insert(RecurringRule rule);
  Future<void> setActive(int id, bool active);
  Future<void> delete(int id);
  Future<void> markGenerated(int id, DateTime day);
}

class RecurringController extends GetxController {
  RecurringController(this._store);

  final RecurringStore _store;
  final state = const ResourceState<List<RecurringRule>>.idle().obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    state.value = const ResourceState.loading();
    try {
      final rules = await _store.getAll();
      state.value = rules.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(rules);
    } catch (_) {
      state.value = ResourceState.error('Gagal memuat transaksi berulang.'.tr);
    }
  }

  Future<bool> remove(int id) async {
    try {
      await _store.delete(id);
      await load();
      return true;
    } catch (_) {
      state.value = ResourceState.error(
        'Gagal menghapus transaksi berulang.'.tr,
      );
      return false;
    }
  }

  Future<bool> setActive(int id, bool active) async {
    try {
      await _store.setActive(id, active);
      await load();
      return true;
    } catch (_) {
      state.value = ResourceState.error('Gagal mengubah status.'.tr);
      return false;
    }
  }
}
