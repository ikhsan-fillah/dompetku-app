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

  /// Menghapus kategori permanen dalam satu transaksi database.
  ///
  /// Transaksi dan transaksi berulang yang memakainya dipindah ke kategori
  /// bawaan "Other" sejenis, draf dilepas dari kategorinya, dan anggaran khusus
  /// kategori ini ikut dihapus. Kategori "Other" bawaan sendiri tidak bisa
  /// dihapus karena menjadi penampung.
  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.transaction((txn) async {
      final rows = await txn.query(
        DatabaseTables.categories,
        where: '${DatabaseColumns.id} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final category = CategoryModel.fromMap(rows.first);
      if (category.isFallback) {
        throw StateError('Kategori penampung tidak bisa dihapus');
      }
      final fallback = await txn.query(
        DatabaseTables.categories,
        columns: [DatabaseColumns.id],
        where:
            '${DatabaseColumns.type} = ? AND ${DatabaseColumns.isDefault} = 1 '
            'AND ${DatabaseColumns.name} = ? AND ${DatabaseColumns.id} != ?',
        whereArgs: [category.type.name, CategoryModel.fallbackName, id],
        limit: 1,
      );
      if (fallback.isEmpty) {
        throw StateError('Kategori penampung tidak ditemukan');
      }
      final fallbackId = fallback.first[DatabaseColumns.id] as int;
      for (final table in [
        DatabaseTables.transactions,
        DatabaseTables.recurringRules,
      ]) {
        await txn.update(
          table,
          {DatabaseColumns.categoryId: fallbackId},
          where: '${DatabaseColumns.categoryId} = ?',
          whereArgs: [id],
        );
      }
      await txn.update(
        DatabaseTables.drafts,
        {DatabaseColumns.categoryId: null},
        where: '${DatabaseColumns.categoryId} = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseTables.budgets,
        where: '${DatabaseColumns.categoryId} = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseTables.categories,
        where: '${DatabaseColumns.id} = ?',
        whereArgs: [id],
      );
    });
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
