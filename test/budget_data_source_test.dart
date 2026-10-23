import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:dompetku_app/features/budget/data/budget_local_data_source.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemoryAppDatabase extends AppDatabase {
  Database? _db;

  @override
  Future<Database> get database async {
    return _db ??= await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 3, onCreate: Migrations.onCreate),
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

final _now = DateTime(2026, 10, 1);

BudgetModel _budget(String name, {bool archived = false}) => BudgetModel(
  name: name,
  amountLimit: 1000000,
  categoryId: 1,
  startDate: DateTime(2026, 10, 1),
  endDate: DateTime(2026, 10, 31),
  isArchived: archived,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MemoryAppDatabase database;
  late BudgetLocalDataSource source;

  setUp(() {
    database = _MemoryAppDatabase();
    source = BudgetLocalDataSource(database);
  });

  tearDown(() => database.close());

  test('delete menghapus anggaran aktif dan hanya yang dipilih', () async {
    final keep = await source.insert(_budget('simpan'));
    final remove = await source.insert(_budget('hapus'));

    await source.delete(remove);

    final left = await source.getAll(includeArchived: true);
    expect(left.map((budget) => budget.id), [keep]);
    expect(await source.getById(remove), isNull);
  });

  test('delete juga menghapus anggaran yang sudah diarsipkan', () async {
    final id = await source.insert(_budget('lama', archived: true));

    await source.delete(id);

    expect(await source.getAll(includeArchived: true), isEmpty);
  });
}
