import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../constant/app_constant.dart';
import 'migrations.dart';

class AppDatabase {
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, AppConstants.databaseName);
    _database = await openDatabase(
      databasePath,
      version: AppConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
    );
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> deleteDatabaseFile() async {
    await close();
    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, AppConstants.databaseName);
    await deleteDatabase(databasePath);
  }
}
