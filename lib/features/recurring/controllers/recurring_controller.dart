import 'dart:async';

import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../models/recurring_rule.dart';
import '../services/recurring_reminders.dart';

/// Antarmuka penyimpanan yang dipakai controller dan layar (mudah di-test).
abstract interface class RecurringStore {
  Future<List<RecurringRule>> getAll();
  Future<int> insert(RecurringRule rule);
  Future<void> update(RecurringRule rule);
  Future<void> setActive(int id, bool active);
  Future<void> delete(int id);
  Future<void> markGenerated(int id, DateTime day);
}

class RecurringController extends GetxController {
  RecurringController(this._store);

  final RecurringStore _store;
  final state = const ResourceState<List<RecurringRule>>.idle().obs;

  /// Aturan yang sedang menampilkan tombol Edit dan Hapus.

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
      // Setiap perubahan aturan berakhir di load(), jadi jadwal pengingat
      // diperbarui di sini.
      if (Get.isRegistered<RecurringReminderService>()) {
        unawaited(Get.find<RecurringReminderService>().reschedule());
      }
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

  /// Mengembalikan aturan yang baru dihapus (tombol Urungkan).
  Future<bool> restoreRule(RecurringRule rule) async {
    try {
      await _store.insert(rule);
      await load();
      return true;
    } catch (_) {
      state.value = ResourceState.error(
        'Gagal mengembalikan transaksi berulang.'.tr,
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
