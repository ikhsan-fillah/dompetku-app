import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/transaction/data/transaction_local_data_source.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
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

TransactionModel _tx(
  DateTime date,
  int amount, {
  TransactionType type = TransactionType.expense,
  int categoryId = 1,
}) => TransactionModel(
  type: type,
  title: 'T',
  amount: amount,
  transactionDate: date,
  categoryId: categoryId,
  createdAt: date,
  updatedAt: date,
);

DateRange _days(DateTime start, DateTime end) =>
    DateRange(start: start, end: end);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MemoryAppDatabase database;
  late TransactionLocalDataSource source;

  setUp(() {
    database = _MemoryAppDatabase();
    source = TransactionLocalDataSource(database);
  });

  tearDown(() => database.close());

  group('rentang hari kalender lokal', () {
    // Transaksi tersimpan UTC; di zona seperti WIB, 00.30 lokal jatuh pada
    // hari sebelumnya di UTC. Hari yang dihitung harus hari lokal.
    test('transaksi dini hari tetap di hari lokalnya', () async {
      await source.insert(_tx(DateTime(2026, 10, 22, 0, 30), 1000));
      await source.insert(_tx(DateTime(2026, 10, 21, 23, 59), 2000));
      await source.insert(_tx(DateTime(2026, 10, 23, 0, 0), 4000));

      final day = _days(DateTime(2026, 10, 22), DateTime(2026, 10, 22));

      expect((await source.getAll(range: day)).map((t) => t.amount), [1000]);
      expect(
        await source.getTotal(type: TransactionType.expense, range: day),
        1000,
      );
      expect(await source.count(range: day), 1);
      expect((await source.getSummary(range: day)).expense, 1000);
    });

    test('hari terakhir rentang ikut dihitung sampai 23.59', () async {
      await source.insert(_tx(DateTime(2026, 10, 31, 23, 59, 59), 500));
      await source.insert(_tx(DateTime(2026, 11, 1, 0, 0, 1), 900));

      final october = _days(DateTime(2026, 10), DateTime(2026, 10, 31));

      expect((await source.getAll(range: october)).map((t) => t.amount), [500]);
    });

    test('rentang beberapa hari mencakup semua transaksinya', () async {
      for (var day = 1; day <= 5; day++) {
        await source.insert(_tx(DateTime(2026, 10, day, 12), day * 100));
      }

      final middle = _days(DateTime(2026, 10, 2), DateTime(2026, 10, 4));

      expect((await source.getAll(range: middle)).map((t) => t.amount), [
        400,
        300,
        200,
      ]);
      expect(await source.count(range: middle), 3);
    });

    test('ringkasan kategori memakai batas yang sama', () async {
      await source.insert(_tx(DateTime(2026, 10, 22, 0, 10), 100));
      await source.insert(_tx(DateTime(2026, 10, 21, 23, 50), 700));

      final summary = await source.getCategorySummary(
        categoryId: 1,
        range: _days(DateTime(2026, 10, 22), DateTime(2026, 10, 22)),
      );

      expect(summary.total, 100);
      expect(summary.count, 1);
    });

    test('getPage dengan rentang sejalan dengan getAll', () async {
      await source.insert(_tx(DateTime(2026, 10, 22, 0, 30), 1000));
      await source.insert(_tx(DateTime(2026, 10, 21, 23, 59), 2000));

      final page = await source.getPage(
        TransactionPageRequest(
          range: _days(DateTime(2026, 10, 22), DateTime(2026, 10, 22)),
        ),
      );

      expect(page.map((t) => t.amount), [1000]);
    });
  });

  group('count dan firstTransactionDate', () {
    test('kosong: nol dan null', () async {
      expect(await source.count(), 0);
      expect(await source.firstTransactionDate(), isNull);
    });

    test('menghitung semua jenis dan mengembalikan tanggal terawal', () async {
      await source.insert(_tx(DateTime(2026, 10, 5, 9), 100));
      await source.insert(
        _tx(DateTime(2025, 2, 10, 9), 200, type: TransactionType.income),
      );
      await source.insert(_tx(DateTime(2026, 8, 1, 9), 300));

      expect(await source.count(), 3);
      final first = await source.firstTransactionDate();
      expect(first!.toLocal(), DateTime(2025, 2, 10, 9));
    });
  });
}
