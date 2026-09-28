import '../data/budget_local_data_source.dart';
import '../models/budget_model.dart';
import 'budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(this._dataSource);

  final BudgetLocalDataSource _dataSource;

  @override
  Future<List<BudgetModel>> getAll({bool includeArchived = false}) {
    return _dataSource.getAll(includeArchived: includeArchived);
  }

  @override
  Future<BudgetModel?> getById(int id) => _dataSource.getById(id);

  @override
  Future<int> insert(BudgetModel budget) => _dataSource.insert(budget);

  @override
  Future<void> update(BudgetModel budget) => _dataSource.update(budget);

  @override
  Future<void> archive(int id) => _dataSource.archive(id);
}
