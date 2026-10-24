import 'dart:convert';

import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constant/app_constant.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';

/// Isi berkas cadangan yang sudah dibaca, ditampilkan sebelum dipulihkan.
class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.schemaVersion,
    required this.tables,
  });

  final DateTime createdAt;
  final int schemaVersion;

  /// Baris per tabel, persis seperti di basis data.
  final Map<String, List<Map<String, Object?>>> tables;

  int count(String table) => tables[table]?.length ?? 0;
}

/// Berkas yang bukan cadangan Tally atau tidak bisa dipulihkan.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cadangan seluruh data sebagai satu berkas JSON (.tally) dan pemulihannya.
///
/// Foto struk tidak ikut; hanya data di basis data.
class BackupService {
  BackupService(this._appDatabase, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _appDatabase;
  final DateTime Function() _clock;

  static const format = 'tally-backup';
  static const extension = 'tally';

  /// Urutan sisip (kategori dulu karena dirujuk transaksi dan anggaran).
  static const tables = [
    DatabaseTables.categories,
    DatabaseTables.transactions,
    DatabaseTables.budgets,
    DatabaseTables.recurringRules,
    DatabaseTables.drafts,
    DatabaseTables.savingsGoals,
  ];

  /// Jumlah baris per tabel saat ini.
  Future<Map<String, int>> counts() async {
    final database = await _appDatabase.database;
    return {
      for (final table in tables)
        table:
            Sqflite.firstIntValue(
              await database.rawQuery('SELECT COUNT(*) FROM $table'),
            ) ??
            0,
    };
  }

  /// Seluruh data sebagai teks JSON.
  Future<String> encode() async {
    final database = await _appDatabase.database;
    final data = <String, Object?>{};
    for (final table in tables) {
      data[table] = await database.query(table);
    }
    return jsonEncode({
      'format': format,
      'schemaVersion': AppConstants.databaseVersion,
      'createdAt': _clock().toUtc().toIso8601String(),
      'tables': data,
    });
  }

  /// Membaca isi berkas cadangan. Melempar [BackupFormatException] bila
  /// bukan cadangan Tally atau dari versi app yang lebih baru.
  BackupPreview decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw BackupFormatException('Berkas ini bukan cadangan Tally.'.tr);
    }
    if (root is! Map<String, Object?> || root['format'] != format) {
      throw BackupFormatException('Berkas ini bukan cadangan Tally.'.tr);
    }
    final version = root['schemaVersion'];
    final created = DateTime.tryParse('${root['createdAt']}');
    final rawTables = root['tables'];
    if (version is! int || created == null || rawTables is! Map) {
      throw BackupFormatException('Berkas cadangan rusak.'.tr);
    }
    if (version > AppConstants.databaseVersion) {
      throw BackupFormatException(
        'Cadangan dari Tally versi lebih baru. Perbarui app dulu.'.tr,
      );
    }
    final parsed = <String, List<Map<String, Object?>>>{};
    for (final table in tables) {
      final rows = rawTables[table];
      if (rows == null) continue;
      if (rows is! List) {
        throw BackupFormatException('Berkas cadangan rusak.'.tr);
      }
      parsed[table] = [
        for (final row in rows)
          if (row is Map) Map<String, Object?>.from(row),
      ];
    }
    return BackupPreview(
      createdAt: created.toLocal(),
      schemaVersion: version,
      tables: parsed,
    );
  }

  /// Mengganti seluruh data dengan isi cadangan dalam satu transaksi SQL;
  /// bila gagal di tengah, data lama tetap utuh.
  Future<void> restore(BackupPreview backup) async {
    final database = await _appDatabase.database;
    await database.transaction((txn) async {
      for (final table in tables.reversed) {
        await txn.delete(table);
      }
      for (final table in tables) {
        final rows = backup.tables[table];
        if (rows == null || rows.isEmpty) continue;
        // Kolom yang tidak ada lagi (cadangan lama/baru) dilewati.
        final columns = {
          for (final info in await txn.rawQuery('PRAGMA table_info($table)'))
            info['name'] as String,
        };
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert(table, {
            for (final entry in row.entries)
              if (columns.contains(entry.key)) entry.key: entry.value,
          });
        }
        await batch.commit(noResult: true);
      }
    });
  }
}
