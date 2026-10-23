import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/validator.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryController extends GetxController {
  CategoryController(this._repository);

  /// Batas favorit per jenis, sama dengan jumlah yang tampil di Beranda.
  static const maxFavorites = 4;

  final CategoryRepository _repository;
  final state = const ResourceState<List<CategoryModel>>.idle().obs;
  final selectedType = TransactionType.expense.obs;

  /// Pesan kegagalan aksi (mis. batas favorit) tanpa mengganti daftar dengan
  /// layar error.
  final lastError = RxnString();

  /// Kategori aktif untuk tipe yang sedang dipilih, sesuai urutan tersimpan.
  List<CategoryModel> get visibleCategories {
    final data = state.value.data ?? const <CategoryModel>[];
    return data.where((c) => c.type == selectedType.value).toList();
  }

  void setType(TransactionType type) {
    selectedType.value = type;
  }

  int favoriteCount(TransactionType type, {int? excludeId}) =>
      (state.value.data ?? const <CategoryModel>[])
          .where((c) => c.type == type && c.isFavorite && c.id != excludeId)
          .length;

  bool canAddFavorite(TransactionType type, {int? excludeId}) =>
      favoriteCount(type, excludeId: excludeId) < maxFavorites;

  void _favoriteLimitReached() {
    lastError.value = 'Maksimal @count kategori favorit.'.trParams({
      'count': '$maxFavorites',
    });
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
      state.value = ResourceState.error('Gagal memuat kategori.'.tr);
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
    final nameError = requiredText(
      category.name,
      fieldName: 'Nama kategori'.tr,
    );
    if (nameError != null) {
      state.value = ResourceState.error(nameError);
      return false;
    }
    final previous = (state.value.data ?? const <CategoryModel>[])
        .where((c) => c.id != null && c.id == category.id)
        .firstOrNull;
    // Kategori baru yang bukan favorit tetap di akhir daftar.
    final favoriteChanged = previous == null
        ? category.isFavorite
        : previous.isFavorite != category.isFavorite ||
              previous.type != category.type;
    if (category.isFavorite &&
        (previous == null ||
            !previous.isFavorite ||
            previous.type != category.type) &&
        !canAddFavorite(category.type, excludeId: category.id)) {
      _favoriteLimitReached();
      return false;
    }
    lastError.value = null;
    try {
      var id = category.id;
      if (id == null) {
        id = await _repository.insert(category);
      } else {
        await _repository.update(category);
      }
      if (favoriteChanged) {
        await load(silent: true);
        await _applyFavoriteOrder(
          category.type,
          changedId: id,
          nowFavorite: category.isFavorite,
        );
      }
      return await _reloadAfterWrite();
    } catch (_) {
      state.value = ResourceState.error('Gagal menyimpan kategori.'.tr);
      return false;
    }
  }

  /// Menghapus kategori permanen. Transaksinya dipindah ke kategori "Other"
  /// bawaan sejenis (lihat `CategoryLocalDataSource.delete`).
  Future<bool> delete(int id) async {
    lastError.value = null;
    try {
      await _repository.delete(id);
      return await _reloadAfterWrite();
    } catch (_) {
      lastError.value = 'Gagal menghapus kategori.'.tr;
      return false;
    }
  }

  /// Favorit tipe [type] selalu di urutan teratas (1 sampai 4). Kategori yang
  /// baru jadi favorit masuk di ujung blok favorit; yang dilepas pindah ke
  /// awal daftar biasa.
  static List<CategoryModel> favoritesFirst(
    List<CategoryModel> visible, {
    int? changedId,
    bool nowFavorite = false,
  }) {
    bool favorite(CategoryModel c) =>
        c.id != null && c.id == changedId ? nowFavorite : c.isFavorite;
    final changed = changedId == null
        ? null
        : visible.where((c) => c.id == changedId).firstOrNull;
    final favorites = [
      for (final c in visible)
        if (favorite(c) && c != changed) c,
    ];
    final rest = [
      for (final c in visible)
        if (!favorite(c) && c != changed) c,
    ];
    if (changed != null) {
      nowFavorite ? favorites.add(changed) : rest.insert(0, changed);
    }
    return [...favorites, ...rest];
  }

  /// Menyusun id semua kategori: urutan tipe [type] diganti [ordered], posisi
  /// tipe lain tetap.
  static List<int> _mergeOrder(
    List<CategoryModel> all,
    TransactionType type,
    List<CategoryModel> ordered,
  ) {
    final result = <CategoryModel>[...all];
    var cursor = 0;
    for (var i = 0; i < all.length; i++) {
      if (all[i].type == type) result[i] = ordered[cursor++];
    }
    return result.map((c) => c.id).whereType<int>().toList();
  }

  Future<void> _applyFavoriteOrder(
    TransactionType type, {
    int? changedId,
    bool nowFavorite = false,
  }) async {
    final all = state.value.data;
    if (all == null) return;
    final visible = all.where((c) => c.type == type).toList();
    final ordered = favoritesFirst(
      visible,
      changedId: changedId,
      nowFavorite: nowFavorite,
    );
    await _repository.reorder(_mergeOrder(all, type, ordered));
  }

  Future<bool> reorder(List<int> ids) async {
    try {
      await _repository.reorder(ids);
      return await _reloadAfterWrite();
    } catch (_) {
      state.value = ResourceState.error('Gagal mengubah urutan kategori.'.tr);
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

    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex.clamp(0, visible.length), moved);

    // Favorit tetap di atas walau digeser ke bawah daftar biasa (dan
    // sebaliknya); urutan di dalam tiap blok mengikuti hasil geser.
    final ordered = favoritesFirst(visible);
    return reorder(_mergeOrder(all, selectedType.value, ordered));
  }
}
