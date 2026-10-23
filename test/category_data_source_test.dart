import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:dompetku_app/features/category/data/category_local_data_source.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemoryAppDatabase extends AppDatabase {
  Database? _db;

  @override
  Future<Database> get database async {
    return _db ??= await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: Migrations.onCreate,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

final _now = DateTime.utc(2026, 10, 1);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MemoryAppDatabase database;
  late CategoryLocalDataSource source;

  setUp(() {
    database = _MemoryAppDatabase();
    source = CategoryLocalDataSource(database);
  });

  tearDown(() => database.close());

  Future<int> otherId(TransactionType type) async {
    final all = await source.getAll();
    return all.firstWhere((c) => c.type == type && c.isFallback).id!;
  }

  Future<int> addCategory(String name) => source.insert(
    CategoryModel(
      name: name,
      type: TransactionType.expense,
      iconKey: 'more_horiz',
      colorValue: 0xFF90A4AE,
      isDefault: false,
      isFavorite: false,
      sortOrder: 99,
      isArchived: false,
      createdAt: _now,
      updatedAt: _now,
    ),
  );

  Future<void> addTransaction(int categoryId) async {
    final db = await database.database;
    await db.insert(DatabaseTables.transactions, {
      DatabaseColumns.type: 'expense',
      DatabaseColumns.title: 'Kopi',
      DatabaseColumns.amount: 20000,
      DatabaseColumns.transactionDate: _now.toIso8601String(),
      DatabaseColumns.categoryId: categoryId,
      DatabaseColumns.createdAt: _now.toIso8601String(),
      DatabaseColumns.updatedAt: _now.toIso8601String(),
    });
  }

  Future<void> addBudget(int categoryId) async {
    final db = await database.database;
    await db.insert(DatabaseTables.budgets, {
      DatabaseColumns.name: 'Jajan',
      DatabaseColumns.amountLimit: 100000,
      DatabaseColumns.categoryId: categoryId,
      DatabaseColumns.startDate: _now.toIso8601String(),
      DatabaseColumns.endDate: _now.toIso8601String(),
      DatabaseColumns.createdAt: _now.toIso8601String(),
      DatabaseColumns.updatedAt: _now.toIso8601String(),
    });
  }

  test(
    'hapus kategori memindah transaksinya ke Other dan menghapus anggarannya',
    () async {
      final id = await addCategory('Jajan');
      await addTransaction(id);
      await addTransaction(id);
      await addBudget(id);
      final other = await otherId(TransactionType.expense);

      await source.delete(id);

      final db = await database.database;
      expect(await source.getById(id), isNull);
      final moved = await db.query(
        DatabaseTables.transactions,
        where: '${DatabaseColumns.categoryId} = ?',
        whereArgs: [other],
      );
      expect(moved, hasLength(2));
      expect(await db.query(DatabaseTables.budgets), isEmpty);
    },
  );

  test('kategori Other bawaan tidak bisa dihapus', () async {
    final other = await otherId(TransactionType.expense);

    await expectLater(source.delete(other), throwsStateError);
    expect(await source.getById(other), isNotNull);
  });

  test('kategori tanpa transaksi langsung terhapus', () async {
    final id = await addCategory('Sementara');

    await source.delete(id);

    expect(await source.getById(id), isNull);
  });
}
