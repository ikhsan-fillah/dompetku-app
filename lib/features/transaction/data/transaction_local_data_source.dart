import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';
import 'package:dompetku_app/core/utils/date_range.dart';

import '../models/transaction_model.dart';

class TransactionLocalDataSource {
  TransactionLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<TransactionModel>> getAll({DateRange? range}) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.transactions,
      where: range == null
          ? null
          : 'date(${DatabaseColumns.transactionDate}) BETWEEN date(?) AND date(?)',
      whereArgs: range == null
          ? null
          : [range.start.toIso8601String(), range.end.toIso8601String()],
      orderBy:
          '${DatabaseColumns.transactionDate} DESC, ${DatabaseColumns.id} DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<TransactionModel?> getById(int id) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.transactions,
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : TransactionModel.fromMap(rows.first);
  }

  Future<int> insert(TransactionModel transaction) async {
    final database = await _appDatabase.database;
    return database.insert(DatabaseTables.transactions, transaction.toMap());
  }

  Future<void> update(TransactionModel transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw ArgumentError('Transaction id is required for update');
    }
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.transactions,
      transaction.toMap(),
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.delete(
      DatabaseTables.transactions,
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getByCategory(int categoryId) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.transactions,
      where: '${DatabaseColumns.categoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${DatabaseColumns.transactionDate} DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<int> getTotal({
    required TransactionType type,
    DateRange? range,
  }) async {
    final database = await _appDatabase.database;
    final result = await database.rawQuery(
      '''SELECT COALESCE(SUM(${DatabaseColumns.amount}), 0) AS total
         FROM ${DatabaseTables.transactions}
         WHERE ${DatabaseColumns.type} = ?
         ${range == null ? '' : 'AND date(${DatabaseColumns.transactionDate}) BETWEEN date(?) AND date(?)'}''',
      [
        type.name,
        if (range != null) ...[
          range.start.toIso8601String(),
          range.end.toIso8601String(),
        ],
      ],
    );
    return (result.first['total'] as num).toInt();
  }
}
