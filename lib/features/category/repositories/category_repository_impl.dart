import '../data/category_local_data_source.dart';
import '../models/category_model.dart';
import 'category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dataSource);

  final CategoryLocalDataSource _dataSource;

  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) {
    return _dataSource.getAll(includeArchived: includeArchived);
  }

  @override
  Future<CategoryModel?> getById(int id) => _dataSource.getById(id);

  @override
  Future<int> insert(CategoryModel category) => _dataSource.insert(category);

  @override
  Future<void> update(CategoryModel category) => _dataSource.update(category);

  @override
  Future<void> archive(int id) => _dataSource.archive(id);

  @override
  Future<void> reorder(List<int> orderedIds) => _dataSource.reorder(orderedIds);
}
