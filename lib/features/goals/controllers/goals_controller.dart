import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../data/goal_repository.dart';
import '../models/savings_goal.dart';

/// Daftar tujuan tabungan, setoran, dan perayaan saat target tercapai.
class GoalsController extends GetxController {
  GoalsController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final GoalRepository _repository;
  final DateTime Function() _clock;
  final state = const ResourceState<List<SavingsGoal>>.idle().obs;

  List<SavingsGoal> get goals => state.value.data ?? const <SavingsGoal>[];

  int get totalSaved => goals.fold(0, (sum, g) => sum + g.savedAmount);

  int get totalTarget => goals.fold(0, (sum, g) => sum + g.targetAmount);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (state.value.status != ResourceStatus.success) {
      state.value = const ResourceState.loading();
    }
    try {
      final goals = await _repository.getAll();
      state.value = goals.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(goals);
    } catch (_) {
      state.value = ResourceState.error('Gagal memuat tabungan.'.tr);
    }
  }

  /// Menyimpan tujuan baru atau yang diubah.
  Future<bool> save(SavingsGoal goal) async {
    try {
      final now = _clock();
      final reached = goal.isReached;
      final stamped = goal.copyWith(
        updatedAt: now,
        completedAt: reached ? goal.completedAt ?? now : null,
        clearCompletedAt: !reached,
      );
      if (goal.id == null) {
        await _repository.insert(stamped);
      } else {
        await _repository.update(stamped);
      }
      await load();
      return true;
    } catch (_) {
      state.value = ResourceState.error('Gagal menyimpan tabungan.'.tr);
      return false;
    }
  }

  /// Menambah (positif) atau mengambil (negatif) uang dari tujuan.
  /// Mengembalikan true bila tujuan baru saja mencapai target.
  Future<bool> deposit(SavingsGoal goal, int amount) async {
    final wasReached = goal.completedAt != null;
    final saved = (goal.savedAmount + amount).clamp(0, 1 << 52);
    final updated = goal.copyWith(savedAmount: saved);
    await save(updated);
    return !wasReached && updated.isReached;
  }

  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      await load();
      return true;
    } catch (_) {
      state.value = ResourceState.error('Gagal menghapus tabungan.'.tr);
      return false;
    }
  }

  /// Mengembalikan tujuan yang baru dihapus (tombol Urungkan).
  Future<bool> restore(SavingsGoal goal) async {
    try {
      await _repository.insert(goal);
      await load();
      return true;
    } catch (_) {
      state.value = ResourceState.error('Gagal mengembalikan tabungan.'.tr);
      return false;
    }
  }
}
