import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/validator.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryController extends GetxController {
  CategoryController(this._repository);

  final CategoryRepository _repository;
  final state = const ResourceState<List<CategoryModel>>.idle().obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({bool includeArchived = false}) async {
    state.value = const ResourceState.loading();
    try {
      final categories = await _repository.getAll(includeArchived: includeArchived);
      state.value = categories.isEmpty ? const ResourceState.empty() : ResourceState.success(categories);
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat kategori.');
    }
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
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menyimpan kategori.');
      return false;
    }
  }

  Future<bool> archive(int id) async {
    try {
      await _repository.archive(id);
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal mengarsipkan kategori.');
      return false;
    }
  }

  Future<bool> reorder(List<int> ids) async {
    try {
      await _repository.reorder(ids);
      await load();
      return state.value.status != ResourceStatus.error;
    } catch (_) {
      state.value = const ResourceState.error('Gagal mengubah urutan kategori.');
      return false;
    }
  }
}
