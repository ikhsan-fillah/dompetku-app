import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';
import 'package:sqflite/sqflite.dart';

import '../models/draft_model.dart';

class DraftLocalDataSource {
  DraftLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  static const _table = 'drafts';

  Future<List<DraftModel>> getPending() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      _table,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'detected_at DESC, id DESC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<int> countPending() async {
    final database = await _appDatabase.database;
    final rows = await database.rawQuery(
      "SELECT COUNT(*) AS c FROM $_table WHERE status = 'pending'",
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Draft dengan dedupe_key yang sama diabaikan, termasuk yang sudah dismiss.
  Future<void> insertIfNew(DraftModel draft) async {
    final database = await _appDatabase.database;
    await database.insert(
      _table,
      _toMap(draft),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Apakah sudah ada draft (apa pun statusnya) dengan sumber dan nominal yang
  /// sama dalam [window] dari [at].
  Future<bool> existsNear({
    required String source,
    required int amount,
    required DateTime at,
    required Duration window,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      _table,
      columns: ['id'],
      where: 'source = ? AND amount = ? AND detected_at BETWEEN ? AND ?',
      whereArgs: [
        source,
        amount,
        at.subtract(window).toUtc().toIso8601String(),
        at.add(window).toUtc().toIso8601String(),
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> update(DraftModel draft) async {
    final id = draft.id;
    if (id == null) throw ArgumentError('Draft id is required');
    final database = await _appDatabase.database;
    await database.update(
      _table,
      {
        'amount': draft.amount,
        'merchant': draft.merchant,
        'category_id': draft.categoryId,
      },
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> setStatus(int id, DraftStatus status) async {
    final database = await _appDatabase.database;
    await database.update(
      _table,
      {'status': status.name},
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toMap(DraftModel draft) => {
    'source': draft.source,
    'kind': draft.kind.name,
    'amount': draft.amount,
    'merchant': draft.merchant,
    'category_id': draft.categoryId,
    'payment_method': draft.paymentMethod?.name,
    'detected_at': draft.detectedAt.toUtc().toIso8601String(),
    'status': draft.status.name,
    'dedupe_key': draft.dedupeKey,
    'needs_review': draft.needsReview ? 1 : 0,
    'recurring_rule_id': draft.recurringRuleId,
  };

  DraftModel _fromMap(Map<String, Object?> map) => DraftModel(
    id: map['id'] as int,
    source: map['source'] as String,
    kind: TransactionType.values.byName(map['kind'] as String),
    amount: map['amount'] as int,
    merchant: map['merchant'] as String?,
    categoryId: map['category_id'] as int?,
    paymentMethod: map['payment_method'] == null
        ? null
        : PaymentMethod.values.byName(map['payment_method'] as String),
    detectedAt: DateTime.parse(map['detected_at'] as String),
    status: DraftStatus.values.byName(map['status'] as String),
    dedupeKey: map['dedupe_key'] as String,
    needsReview: (map['needs_review'] as int) == 1,
    recurringRuleId: map['recurring_rule_id'] as int?,
  );
}
