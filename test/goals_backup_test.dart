import 'package:dompetku_app/core/constant/app_constant.dart';
import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/backup/services/backup_service.dart';
import 'package:dompetku_app/features/goals/controllers/goals_controller.dart';
import 'package:dompetku_app/features/goals/data/goal_repository.dart';
import 'package:dompetku_app/features/goals/models/savings_goal.dart';
import 'package:dompetku_app/features/transaction/data/transaction_local_data_source.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Basis data di memori dengan skema terbaru (termasuk savings_goals).
class _MemoryAppDatabase extends AppDatabase {
  Database? _db;

  @override
  Future<Database> get database async {
    return _db ??= await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onCreate: Migrations.onCreate,
        onUpgrade: Migrations.onUpgrade,
        singleInstance: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

SavingsGoal _goal(String name, int target, {int saved = 0, int? id}) =>
    SavingsGoal(
      id: id,
      name: name,
      emoji: '🎯',
      targetAmount: target,
      savedAmount: saved,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );

TransactionModel _tx(
  int amount, {
  int categoryId = 1,
  TransactionType type = TransactionType.expense,
  int day = 10,
  String title = 'T',
}) => TransactionModel(
  type: type,
  title: title,
  amount: amount,
  transactionDate: DateTime(2026, 10, day, 12),
  categoryId: categoryId,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MemoryAppDatabase database;

  setUp(() => database = _MemoryAppDatabase());
  tearDown(() => database.close());

  test('skema v5 membuat tabel savings_goals', () async {
    final db = await database.database;
    final names = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((row) => row['name']).toSet();

    expect(AppConstants.databaseVersion, 5);
    expect(names, contains(DatabaseTables.savingsGoals));
  });

  group('GoalsController', () {
    late GoalsController controller;

    setUp(() {
      controller = GoalsController(
        GoalRepositoryImpl(database),
        clock: () => DateTime(2026, 10, 24, 9),
      );
    });

    test('kosong lalu terisi; total terkumpul dan target dijumlah', () async {
      await controller.load();
      expect(controller.state.value.status, ResourceStatus.empty);

      await controller.save(_goal('Laptop', 10000000, saved: 2500000));
      await controller.save(_goal('Liburan', 4000000, saved: 500000));

      expect(controller.goals.map((g) => g.name), ['Laptop', 'Liburan']);
      expect(controller.totalSaved, 3000000);
      expect(controller.totalTarget, 14000000);
    });

    test('setoran yang mencapai target mengembalikan true sekali', () async {
      await controller.save(_goal('HP', 1000000, saved: 900000));
      final goal = controller.goals.single;

      expect(await controller.deposit(goal, 100000), isTrue);
      final reached = controller.goals.single;
      expect(reached.isReached, isTrue);
      expect(reached.completedAt, isNotNull);

      expect(await controller.deposit(reached, 50000), isFalse);
    });

    test('ambil tidak membuat saldo negatif', () async {
      await controller.save(_goal('Dana darurat', 1000000, saved: 100000));

      await controller.deposit(controller.goals.single, -500000);

      expect(controller.goals.single.savedAmount, 0);
    });

    test('hapus lalu urungkan mengembalikan tujuan', () async {
      await controller.save(_goal('Sepeda', 3000000));
      final goal = controller.goals.single;

      expect(await controller.delete(goal.id!), isTrue);
      expect(controller.goals, isEmpty);

      expect(await controller.restore(goal), isTrue);
      expect(controller.goals.single.name, 'Sepeda');
    });
  });

  group('BackupService', () {
    test('cadangan lalu pulihkan mengembalikan semua data', () async {
      final transactions = TransactionLocalDataSource(database);
      await transactions.insert(_tx(25000, title: 'Kopi'));
      await transactions.insert(_tx(50000, title: 'Makan'));
      await GoalRepositoryImpl(database).insert(_goal('Laptop', 1000));
      final service = BackupService(
        database,
        clock: () => DateTime.utc(2026, 10, 24, 14),
      );
      final before = await service.counts();
      final text = await service.encode();

      // Data berubah setelah cadangan dibuat.
      await transactions.insert(_tx(99000, title: 'Setelah cadangan'));
      final db = await database.database;
      await db.delete(DatabaseTables.savingsGoals);

      final preview = service.decode(text);
      expect(preview.count(DatabaseTables.transactions), 2);
      expect(preview.count(DatabaseTables.savingsGoals), 1);
      expect(preview.createdAt, DateTime.utc(2026, 10, 24, 14).toLocal());

      await service.restore(preview);

      expect(await service.counts(), before);
      final titles = (await transactions.getAll()).map((t) => t.title).toSet();
      expect(titles, {'Kopi', 'Makan'});
    });

    test('kolom yang tidak dikenal dilewati saat pulihkan', () async {
      final service = BackupService(database);
      final preview = service.decode(
        '{"format":"tally-backup","schemaVersion":4,'
        '"createdAt":"2026-10-01T00:00:00.000Z","tables":{"savings_goals":'
        '[{"id":7,"name":"Lama","emoji":"🎯","target_amount":500,'
        '"saved_amount":0,"created_at":"2026-10-01","updated_at":"2026-10-01",'
        '"kolom_lama":1}]}}',
      );

      await service.restore(preview);

      expect((await GoalRepositoryImpl(database).getAll()).single.name, 'Lama');
    });

    test('berkas asing, rusak, atau dari versi lebih baru ditolak', () {
      final service = BackupService(database);

      expect(
        () => service.decode('bukan json'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => service.decode('{"format":"lain"}'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => service.decode(
          '{"format":"tally-backup","schemaVersion":99,'
          '"createdAt":"2026-10-01T00:00:00.000Z","tables":{}}',
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('saringan halaman transaksi', () {
    late TransactionLocalDataSource source;

    setUp(() async {
      source = TransactionLocalDataSource(database);
      await source.insert(_tx(10000, categoryId: 1));
      await source.insert(_tx(60000, categoryId: 2));
      await source.insert(_tx(150000, categoryId: 2));
      await source.insert(_tx(300000, categoryId: 1, day: 20));
    });

    final october = DateRange(
      start: DateTime(2026, 10),
      end: DateTime(2026, 10, 31),
    );

    test('kategori jamak dan rentang nominal', () async {
      final request = TransactionPageRequest(
        range: october,
        categoryIds: const {2},
        minAmount: 50000,
        maxAmount: 100000,
      );

      expect((await source.getPage(request)).map((t) => t.amount), [60000]);
      expect(await source.countPage(request), 1);
    });

    test('tanpa saringan menghitung semuanya', () async {
      expect(await source.countPage(TransactionPageRequest(range: october)), 4);
    });

    test('rentang tanggal satu hari', () async {
      final request = TransactionPageRequest(
        range: DateRange(
          start: DateTime(2026, 10, 20),
          end: DateTime(2026, 10, 20),
        ),
      );

      expect(await source.countPage(request), 1);
    });
  });
}
