import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';
import 'package:dompetku_app/core/utils/date_range.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../services/transaction_list_service.dart';

class TransactionLocalDataSource implements TransactionPageRepository {
  TransactionLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<TransactionModel>> getAll({DateRange? range}) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.transactions,
      where: range == null ? null : _rangeSql(DatabaseColumns.transactionDate),
      whereArgs: range == null ? null : _rangeArgs(range),
      orderBy:
          '${DatabaseColumns.transactionDate} DESC, ${DatabaseColumns.id} DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  /// Tanggal disimpan dalam UTC, sedangkan rentang adalah hari kalender
  /// lokal. Membandingkan batas UTC dari awal hari pertama sampai awal hari
  /// sesudah hari terakhir menjaga transaksi dini hari tetap di harinya, dan
  /// bisa memakai indeks tanggal. Awalan "Z" dibuang supaya urutan teksnya
  /// tetap benar untuk nilai dengan mikrodetik.
  static String _rangeSql(String column) => '$column >= ? AND $column < ?';

  static List<Object?> _rangeArgs(DateRange range) {
    String bound(DateTime localDay) {
      final iso = localDay.toUtc().toIso8601String();
      return iso.endsWith('Z') ? iso.substring(0, iso.length - 1) : iso;
    }

    return [
      bound(DateTime(range.start.year, range.start.month, range.start.day)),
      bound(DateTime(range.end.year, range.end.month, range.end.day + 1)),
    ];
  }

  /// Jumlah transaksi (semua jenis), opsional pada [range].
  Future<int> count({DateRange? range}) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''SELECT COUNT(*) AS c FROM ${DatabaseTables.transactions}
         ${range == null ? '' : 'WHERE ${_rangeSql(DatabaseColumns.transactionDate)}'}''',
      [if (range != null) ..._rangeArgs(range)],
    );
    return (rows.first['c'] as num).toInt();
  }

  /// Waktu transaksi paling awal, atau null bila belum ada.
  Future<DateTime?> firstTransactionDate() async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      'SELECT MIN(${DatabaseColumns.transactionDate}) AS first FROM ${DatabaseTables.transactions}',
    );
    final value = rows.first['first'] as String?;
    return value == null ? null : DateTime.parse(value);
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
         ${range == null ? '' : 'AND ${_rangeSql(DatabaseColumns.transactionDate)}'}''',
      [type.name, if (range != null) ..._rangeArgs(range)],
    );
    return (result.first['total'] as num).toInt();
  }

  @override
  Future<List<TransactionModel>> getPage(TransactionPageRequest request) async {
    final database = await _appDatabase.database;
    final filter = _where(request);
    final rows = await database.rawQuery(
      '''SELECT t.* FROM ${DatabaseTables.transactions} t
         LEFT JOIN ${DatabaseTables.categories} c
           ON c.${DatabaseColumns.id} = t.${DatabaseColumns.categoryId}
         WHERE ${filter.sql}
         ORDER BY ${request.categoryId != null ? _categoryOrderBy(request.dateSort) : _orderBy(request.sort)}
         LIMIT ? OFFSET ?''',
      [...filter.args, request.limit, request.offset],
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<TransactionSummary> getSummary({
    DateRange? range,
    TransactionTypeFilter filter = TransactionTypeFilter.all,
    String query = '',
  }) async {
    final database = await _appDatabase.database;
    final where = _where(
      TransactionPageRequest(range: range, filter: filter, query: query),
    );
    final rows = await database.rawQuery('''SELECT
         COALESCE(SUM(CASE WHEN t.${DatabaseColumns.type} = 'income' THEN t.${DatabaseColumns.amount} ELSE 0 END), 0) AS income,
         COALESCE(SUM(CASE WHEN t.${DatabaseColumns.type} = 'expense' THEN t.${DatabaseColumns.amount} ELSE 0 END), 0) AS expense
         FROM ${DatabaseTables.transactions} t
         LEFT JOIN ${DatabaseTables.categories} c
           ON c.${DatabaseColumns.id} = t.${DatabaseColumns.categoryId}
         WHERE ${where.sql}''', where.args);
    final row = rows.first;
    return TransactionSummary(
      income: (row['income'] as num).toInt(),
      expense: (row['expense'] as num).toInt(),
    );
  }

  @override
  Future<CategoryTransactionSummary> getCategorySummary({
    required int categoryId,
    DateRange? range,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      '''SELECT COALESCE(SUM(${DatabaseColumns.amount}), 0) AS total,
         COUNT(*) AS count FROM ${DatabaseTables.transactions}
         WHERE ${DatabaseColumns.categoryId} = ?
         ${range == null ? '' : 'AND ${_rangeSql(DatabaseColumns.transactionDate)}'}''',
      [categoryId, if (range != null) ..._rangeArgs(range)],
    );
    return CategoryTransactionSummary(
      total: (rows.first['total'] as num).toInt(),
      count: (rows.first['count'] as num).toInt(),
    );
  }

  ({String sql, List<Object?> args}) _where(TransactionPageRequest request) {
    final clauses = <String>['1 = 1'];
    final args = <Object?>[];
    if (request.categoryId != null) {
      clauses.add('t.${DatabaseColumns.categoryId} = ?');
      args.add(request.categoryId);
    }
    if (request.filter != TransactionTypeFilter.all) {
      clauses.add('t.${DatabaseColumns.type} = ?');
      args.add(
        request.filter == TransactionTypeFilter.income ? 'income' : 'expense',
      );
    }
    if (request.range != null) {
      clauses.add(_rangeSql('t.${DatabaseColumns.transactionDate}'));
      args.addAll(_rangeArgs(request.range!));
    }
    final query = request.query.trim().toLowerCase();
    if (query.isNotEmpty) {
      clauses.add('''lower(
        t.${DatabaseColumns.title} || ' ' ||
        coalesce(t.${DatabaseColumns.note}, '') || ' ' ||
        coalesce(t.${DatabaseColumns.merchantOrSource}, '') || ' ' ||
        coalesce(c.${DatabaseColumns.name}, '')
      ) LIKE ?''');
      args.add('%$query%');
    }
    return (sql: clauses.join(' AND '), args: args);
  }

  String _orderBy(TransactionSort sort) => switch (sort) {
    TransactionSort.terbaru =>
      't.${DatabaseColumns.transactionDate} DESC, t.${DatabaseColumns.id} DESC',
    TransactionSort.terlama =>
      't.${DatabaseColumns.transactionDate} ASC, t.${DatabaseColumns.id} ASC',
    TransactionSort.nominalTerbesar =>
      't.${DatabaseColumns.amount} DESC, t.${DatabaseColumns.transactionDate} DESC, t.${DatabaseColumns.id} DESC',
    TransactionSort.nominalTerkecil =>
      't.${DatabaseColumns.amount} ASC, t.${DatabaseColumns.transactionDate} DESC, t.${DatabaseColumns.id} DESC',
    TransactionSort.namaAZ =>
      'lower(t.${DatabaseColumns.title}) ASC, t.${DatabaseColumns.transactionDate} DESC, t.${DatabaseColumns.id} DESC',
    TransactionSort.namaZA =>
      'lower(t.${DatabaseColumns.title}) DESC, t.${DatabaseColumns.transactionDate} DESC, t.${DatabaseColumns.id} DESC',
    TransactionSort.kategoriAZ =>
      'lower(coalesce(c.${DatabaseColumns.name}, \'Tanpa kategori\')) ASC, t.${DatabaseColumns.transactionDate} DESC, t.${DatabaseColumns.id} DESC',
  };

  String _categoryOrderBy(TransactionDateSort sort) =>
      sort == TransactionDateSort.newest
      ? 't.${DatabaseColumns.transactionDate} DESC, t.${DatabaseColumns.createdAt} DESC, t.${DatabaseColumns.id} DESC'
      : 't.${DatabaseColumns.transactionDate} ASC, t.${DatabaseColumns.createdAt} ASC, t.${DatabaseColumns.id} ASC';
}
