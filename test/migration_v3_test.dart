import 'dart:io';

import 'package:dompetku_app/core/constant/app_constant.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openV2(String path) async {
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, icon_key TEXT NOT NULL, color_value INTEGER NOT NULL, is_default INTEGER NOT NULL DEFAULT 0, is_favorite INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0, is_archived INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, title TEXT NOT NULL, amount INTEGER NOT NULL, currency TEXT NOT NULL DEFAULT \'IDR\', transaction_date TEXT NOT NULL, category_id INTEGER NOT NULL, merchant_or_source TEXT, payment_method TEXT, note TEXT, receipt_path TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE budgets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, amount_limit INTEGER NOT NULL, category_id INTEGER, start_date TEXT NOT NULL, end_date TEXT NOT NULL, is_archived INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
        );
        await db.execute(
          "INSERT INTO categories (name, type, icon_key, color_value, created_at, updated_at) VALUES ('Other', 'expense', 'more_horiz', 0, '2026-09-01', '2026-09-01')",
        );
      },
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database terbaru membuat tabel recurring_rules dan drafts', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onCreate: Migrations.onCreate,
        onUpgrade: Migrations.onUpgrade,
      ),
    );
    addTearDown(db.close);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((row) => row['name']).toSet();

    expect(AppConstants.databaseVersion, 4);
    expect(names, containsAll(['recurring_rules', 'drafts']));
  });

  test(
    'upgrade dari v2 mempertahankan data lama dan menambah tabel baru',
    () async {
      final dir = await Directory.systemTemp.createTemp('tally_migration_');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/upgrade.db';
      final old = await _openV2(path);
      await old.insert('transactions', {
        'type': 'expense',
        'title': 'Kopi',
        'amount': 25000,
        'currency': 'IDR',
        'transaction_date': '2026-09-01T00:00:00.000Z',
        'category_id': 1,
        'created_at': '2026-09-01T00:00:00.000Z',
        'updated_at': '2026-09-01T00:00:00.000Z',
      });
      await old.close();

      final upgraded = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: Migrations.onCreate,
          onUpgrade: Migrations.onUpgrade,
        ),
      );
      addTearDown(upgraded.close);

      final rows = await upgraded.query('transactions');
      expect(rows.length, 1);
      expect(rows.first['title'], 'Kopi');

      final tables = await upgraded.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((row) => row['name']).toSet();
      expect(names, containsAll(['recurring_rules', 'drafts']));
    },
  );

  test('tabel drafts menolak dedupe_key ganda', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: Migrations.onCreate,
        onUpgrade: Migrations.onUpgrade,
      ),
    );
    addTearDown(db.close);

    final draft = {
      'source': 'GoPay',
      'kind': 'expense',
      'amount': 15000,
      'detected_at': '2026-09-01T10:00:00.000Z',
      'status': 'pending',
      'dedupe_key': 'k1',
      'needs_review': 0,
    };
    await db.insert('drafts', draft);

    expect(() => db.insert('drafts', draft), throwsA(isA<DatabaseException>()));
  });

  test(
    'upgrade v3 ke v4 menambah kolom pengingat tanpa kehilangan aturan',
    () async {
      final dir = await Directory.systemTemp.createTemp('tally_migration_v4_');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/v3.db';
      final v3 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)',
            );
            await db.execute('''
            CREATE TABLE recurring_rules (
              id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
              type TEXT NOT NULL, category_id INTEGER NOT NULL,
              amount INTEGER NOT NULL, frequency TEXT NOT NULL,
              day_of_month INTEGER, weekday INTEGER, start_date TEXT NOT NULL,
              mode TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1,
              last_generated_on TEXT, created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL)
          ''');
            await db.insert('recurring_rules', {
              'name': 'Spotify',
              'type': 'expense',
              'category_id': 1,
              'amount': 55000,
              'frequency': 'monthly',
              'start_date': '2026-09-05',
              'mode': 'ask',
              'created_at': '2026-09-01',
              'updated_at': '2026-09-01',
            });
          },
        ),
      );
      await v3.close();

      final upgraded = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: Migrations.onCreate,
          onUpgrade: Migrations.onUpgrade,
        ),
      );
      addTearDown(upgraded.close);

      final rows = await upgraded.query('recurring_rules');
      expect(rows.single['name'], 'Spotify');
      expect(rows.single.containsKey('remind_days_before'), isTrue);
      expect(rows.single['remind_days_before'], isNull);
    },
  );

  test('upgrade dari v2 langsung ke v4 tidak gagal', () async {
    final dir = await Directory.systemTemp.createTemp('tally_migration_v2v4_');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/v2.db';
    await (await _openV2(path)).close();

    final upgraded = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: Migrations.onCreate,
        onUpgrade: Migrations.onUpgrade,
      ),
    );
    addTearDown(upgraded.close);

    final columns = await upgraded.rawQuery(
      'PRAGMA table_info(recurring_rules)',
    );
    expect(columns.map((c) => c['name']), contains('remind_days_before'));
  });
}
