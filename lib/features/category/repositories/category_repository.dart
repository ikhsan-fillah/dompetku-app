import '../models/category_model.dart';

abstract interface class CategoryRepository {
  Future<List<CategoryModel>> getAll({bool includeArchived = false});
  Future<CategoryModel?> getById(int id);
  Future<int> insert(CategoryModel category);
  Future<void> update(CategoryModel category);
  Future<void> archive(int id);
  Future<void> reorder(List<int> orderedIds);
}
