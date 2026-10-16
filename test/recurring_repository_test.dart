import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:dompetku_app/features/recurring/data/recurring_local_data_source.dart';
import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:dompetku_app/features/recurring/repositories/recurring_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

RecurringRule _rule({int? id, bool active = true}) => RecurringRule(
  id: id,
  name: 'Listrik',
  type: RecurringType.expense,
  categoryId: 1,
  amount: 438000,
  frequency: RecurringFrequency.monthly,
  dayOfMonth: 5,
  startDate: DateTime(2026, 9, 5),
  mode: RecurringMode.ask,
  isActive: active,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDatabase;
  late RecurringRepositoryImpl repository;

  setUp(() async {
    appDatabase = _MemoryAppDatabase();
    repository = RecurringRepositoryImpl(RecurringLocalDataSource(appDatabase));
  });

  tearDown(() async => appDatabase.close());

  test('insert lalu getAll mengembalikan aturan yang sama', () async {
    final id = await repository.insert(_rule());

    final rules = await repository.getAll();

    expect(rules.length, 1);
    expect(rules.first.id, id);
    expect(rules.first.name, 'Listrik');
    expect(rules.first.amount, 438000);
    expect(rules.first.frequency, RecurringFrequency.monthly);
    expect(rules.first.dayOfMonth, 5);
  });

  test('setActive menonaktifkan tanpa menghapus baris', () async {
    final id = await repository.insert(_rule());

    await repository.setActive(id, false);

    final rules = await repository.getAll();
    expect(rules.length, 1);
    expect(rules.first.isActive, isFalse);
  });

  test('markGenerated menyimpan last_generated_on', () async {
    final id = await repository.insert(_rule());
    final day = DateTime(2026, 9, 5);

    await repository.markGenerated(id, day);

    final rule = (await repository.getAll()).single;
    expect(rule.lastGeneratedOn, day);
  });

  test('delete menghapus aturan', () async {
    final id = await repository.insert(_rule());

    await repository.delete(id);

    expect(await repository.getAll(), isEmpty);
  });
}

class _MemoryAppDatabase extends AppDatabase {
  Database? _db;

  @override
  Future<Database> get database async {
    return _db ??= await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, icon_key TEXT NOT NULL, color_value INTEGER NOT NULL, is_default INTEGER NOT NULL DEFAULT 0, is_favorite INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0, is_archived INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            "INSERT INTO categories (name, type, icon_key, color_value, created_at, updated_at) VALUES ('Bills', 'expense', 'receipt_long', 0, '2026-09-01', '2026-09-01')",
          );
          await Migrations.createRecurringAndDrafts(db);
        },
      ),
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
