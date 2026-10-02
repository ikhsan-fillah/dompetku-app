import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/validator.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryController extends GetxController {
  CategoryController(this._repository);

  final CategoryRepository _repository;
  final state = const ResourceState<List<CategoryModel>>.idle().obs;
  final selectedType = TransactionType.expense.obs;

  /// Kategori aktif untuk tipe yang sedang dipilih, sesuai urutan tersimpan.
  List<CategoryModel> get visibleCategories {
    final data = state.value.data ?? const <CategoryModel>[];
    return data.where((c) => c.type == selectedType.value).toList();
  }

  void setType(TransactionType type) {
    selectedType.value = type;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Memuat kategori. Bila [silent] true dan data sudah tampil,
  /// layar tidak berkedip ke keadaan memuat.
  Future<void> load({bool includeArchived = false, bool silent = false}) async {
    if (!silent || state.value.status != ResourceStatus.success) {
      state.value = const ResourceState.loading();
    }
    try {
      final categories = await _repository.getAll(
        includeArchived: includeArchived,
      );
      state.value = categories.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(categories);
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat kategori.');
    }
  }

  /// Memberi tahu dashboard dan layar lain bahwa data kategori berubah.
  void _notifyDataChanged() {
    if (Get.isRegistered<DataRefreshService>()) {
      Get.find<DataRefreshService>().version.value++;
    }
  }

  Future<bool> _reloadAfterWrite() async {
    await load(silent: true);
    final ok = state.value.status != ResourceStatus.error;
    if (ok) _notifyDataChanged();
    return ok;
  }

  Future<bool> save(CategoryModel category) async {
    final nameError = requiredText(category.name, fieldName: 'Nama kategori');
    if (nameError != null) {
      state.value = ResourceState.error(nameError);
      return false;
    }
    try {
      if (category.id == null) {
        await _repository.insert(category);
      } else {
        await _repository.update(category);
      }
      return await _reloadAfterWrite();
    } catch (_) {
      state.value = const ResourceState.error('Gagal menyimpan kategori.');
      return false;
    }
  }

  /// Mengarsipkan kategori. Transaksi yang memakainya tetap aman.
  Future<bool> archive(int id) async {
    try {
      await _repository.archive(id);
      return await _reloadAfterWrite();
    } catch (_) {
      state.value = const ResourceState.error('Gagal mengarsipkan kategori.');
      return false;
    }
  }

  Future<bool> reorder(List<int> ids) async {
    try {
      await _repository.reorder(ids);
      return await _reloadAfterWrite();
    } catch (_) {
      state.value = const ResourceState.error(
        'Gagal mengubah urutan kategori.',
      );
      return false;
    }
  }

  Future<bool> toggleFavorite(CategoryModel category) async {
    if (category.id == null) return false;
    return save(
      CategoryModel(
        id: category.id,
        name: category.name,
        type: category.type,
        iconKey: category.iconKey,
        colorValue: category.colorValue,
        isDefault: category.isDefault,
        isFavorite: !category.isFavorite,
        sortOrder: category.sortOrder,
        isArchived: category.isArchived,
        createdAt: category.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Memindahkan kategori pada daftar tipe terpilih. Posisi tipe lain tetap.
  Future<bool> moveWithinType(int oldIndex, int newIndex) async {
    final all = state.value.data;
    if (all == null) return false;
    final visible = all.where((c) => c.type == selectedType.value).toList();
    if (oldIndex < 0 || oldIndex >= visible.length) return false;

    var target = newIndex;
    if (target > oldIndex) target -= 1;
    target = target.clamp(0, visible.length - 1);

    final moved = visible.removeAt(oldIndex);
    visible.insert(target, moved);

    final result = <CategoryModel>[...all];
    var cursor = 0;
    for (var i = 0; i < all.length; i++) {
      if (all[i].type == selectedType.value) {
        result[i] = visible[cursor++];
      }
    }
    final ids = result.map((c) => c.id).whereType<int>().toList();
    return reorder(ids);
  }
}
