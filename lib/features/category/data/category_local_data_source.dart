import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';

import '../models/category_model.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.categories,
      where: includeArchived ? null : '${DatabaseColumns.isArchived} = ?',
      whereArgs: includeArchived ? null : [0],
      orderBy: '${DatabaseColumns.sortOrder} ASC, ${DatabaseColumns.name} ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getById(int id) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.categories,
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : CategoryModel.fromMap(rows.first);
  }

  Future<int> insert(CategoryModel category) async {
    final database = await _appDatabase.database;
    return database.insert(DatabaseTables.categories, category.toMap());
  }

  Future<void> update(CategoryModel category) async {
    final id = category.id;
    if (id == null) throw ArgumentError('Category id is required for update');
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.categories,
      category.toMap(),
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> archive(int id) async {
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.categories,
      {
        DatabaseColumns.isArchived: 1,
        DatabaseColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorder(List<int> orderedIds) async {
    final database = await _appDatabase.database;
    final batch = database.batch();
    final now = DateTime.now().toUtc().toIso8601String();
    for (var index = 0; index < orderedIds.length; index++) {
      batch.update(
        DatabaseTables.categories,
        {DatabaseColumns.sortOrder: index, DatabaseColumns.updatedAt: now},
        where: '${DatabaseColumns.id} = ?',
        whereArgs: [orderedIds[index]],
      );
    }
    await batch.commit(noResult: true);
  }
}
