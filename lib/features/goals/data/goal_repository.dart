import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';

import '../models/savings_goal.dart';

abstract interface class GoalRepository {
  Future<List<SavingsGoal>> getAll();
  Future<int> insert(SavingsGoal goal);
  Future<void> update(SavingsGoal goal);
  Future<void> delete(int id);
}

/// Tujuan tabungan di SQLite (tabel `savings_goals`, database v5).
class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<SavingsGoal>> getAll() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.savingsGoals,
      orderBy: 'completed_at IS NOT NULL, created_at ASC, id ASC',
    );
    return rows.map(SavingsGoal.fromMap).toList();
  }

  @override
  Future<int> insert(SavingsGoal goal) async {
    final database = await _appDatabase.database;
    return database.insert(DatabaseTables.savingsGoals, goal.toMap());
  }

  @override
  Future<void> update(SavingsGoal goal) async {
    final id = goal.id;
    if (id == null) throw ArgumentError('Goal id is required for update');
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.savingsGoals,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.delete(
      DatabaseTables.savingsGoals,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
