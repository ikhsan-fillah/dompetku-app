import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:dompetku_app/features/drafts/controllers/draft_controller.dart';
import 'package:dompetku_app/features/drafts/data/draft_local_data_source.dart';
import 'package:dompetku_app/features/drafts/models/draft_model.dart';
import 'package:dompetku_app/features/drafts/repositories/draft_repository.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemDb extends AppDatabase {
  Database? _db;

  @override
  Future<Database> get database async {
    return _db ??= await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, icon_key TEXT NOT NULL, color_value INTEGER NOT NULL, is_default INTEGER NOT NULL DEFAULT 0, is_favorite INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0, is_archived INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            "INSERT INTO categories (name, type, icon_key, color_value, created_at, updated_at) VALUES ('Bills', 'expense', 'receipt_long', 0, '2026', '2026')",
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

class _Tx implements TransactionRepository {
  final List<TransactionModel> inserted = [];

  @override
  Future<int> insert(TransactionModel transaction) async {
    inserted.add(transaction);
    return inserted.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DraftModel _draft({String key = 'k1', int categoryId = 1}) => DraftModel(
  source: 'GoPay',
  kind: TransactionType.expense,
  amount: 15000,
  merchant: 'Warung',
  categoryId: categoryId,
  detectedAt: DateTime.utc(2026, 9, 1, 10),
  dedupeKey: key,
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase db;
  late DraftRepository drafts;
  late _Tx tx;
  late DraftController controller;

  setUp(() {
    db = _MemDb();
    drafts = DraftRepositoryImpl(DraftLocalDataSource(db));
    tx = _Tx();
    controller = DraftController(drafts, tx);
  });

  tearDown(() => db.close());

  test('Confirm membuat transaksi dan draft menjadi confirmed', () async {
    await drafts.insertIfNew(_draft());
    final draft = (await drafts.getPending()).single;

    expect(await controller.confirm(draft), isTrue);

    expect(tx.inserted.single.amount, 15000);
    expect(tx.inserted.single.title, 'Warung');
    expect(await drafts.getPending(), isEmpty);
  });

  test('Dismiss tidak memunculkan draft lagi, dan dedupe mencegahnya', () async {
    await drafts.insertIfNew(_draft());
    final draft = (await drafts.getPending()).single;

    await controller.dismiss(draft);
    await drafts.insertIfNew(_draft());

    expect(await drafts.getPending(), isEmpty);
    expect(tx.inserted, isEmpty);
  });

  test('draft dengan dedupe_key sama tidak dobel', () async {
    await drafts.insertIfNew(_draft());
    await drafts.insertIfNew(_draft());

    expect((await drafts.getPending()).length, 1);
  });

  test('Confirm tanpa kategori ditolak', () async {
    await drafts.insertIfNew(_draft(categoryId: 0));
    final draft = (await drafts.getPending()).single;
    final noCategory = DraftModel(
      id: draft.id,
      source: draft.source,
      kind: draft.kind,
      amount: draft.amount,
      detectedAt: draft.detectedAt,
      dedupeKey: 'k-nocat',
    );

    expect(await controller.confirm(noCategory), isFalse);
    expect(tx.inserted, isEmpty);
  });

  test('editAndConfirm memakai nominal baru', () async {
    await drafts.insertIfNew(_draft());
    final draft = (await drafts.getPending()).single;

    await controller.editAndConfirm(draft, amount: 20000, merchant: 'Kopi');

    expect(tx.inserted.single.amount, 20000);
    expect(tx.inserted.single.title, 'Kopi');
  });
}
