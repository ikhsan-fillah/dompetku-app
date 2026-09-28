import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';

import '../models/budget_model.dart';

class BudgetLocalDataSource {
  BudgetLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.budgets,
      where: includeArchived ? null : '${DatabaseColumns.isArchived} = ?',
      whereArgs: includeArchived ? null : [0],
      orderBy: '${DatabaseColumns.startDate} DESC, ${DatabaseColumns.id} DESC',
    );
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<BudgetModel?> getById(int id) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.budgets,
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : BudgetModel.fromMap(rows.first);
  }

  Future<int> insert(BudgetModel budget) async {
    final database = await _appDatabase.database;
    return database.insert(DatabaseTables.budgets, budget.toMap());
  }

  Future<void> update(BudgetModel budget) async {
    final id = budget.id;
    if (id == null) throw ArgumentError('Budget id is required for update');
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.budgets,
      budget.toMap(),
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> archive(int id) async {
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.budgets,
      {
        DatabaseColumns.isArchived: 1,
        DatabaseColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }
}
