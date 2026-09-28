import '../models/budget_model.dart';

abstract interface class BudgetRepository {
  Future<List<BudgetModel>> getAll({bool includeArchived = false});
  Future<BudgetModel?> getById(int id);
  Future<int> insert(BudgetModel budget);
  Future<void> update(BudgetModel budget);
  Future<void> archive(int id);
}
