import 'dart:convert';

import '../../features/budget/repositories/budget_repository.dart';
import '../../features/category/repositories/category_repository.dart';
import '../../features/transaction/repositories/transaction_repository.dart';

/// Membangun payload ekspor JSON lokal (kategori, transaksi, anggaran).
/// Layanan ini tidak mengakses UI, clipboard, atau jaringan.
class LocalDataExportService {
  LocalDataExportService(
    this._categories,
    this._transactions,
    this._budgets, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const schemaVersion = 1;

  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final DateTime Function() _clock;

  Future<Map<String, Object?>> buildPayload({DateTime? exportedAt}) async {
    final categories = await _categories.getAll(includeArchived: true);
    final transactions = await _transactions.getAll();
    final budgets = await _budgets.getAll(includeArchived: true);

    return {
      'app': 'DompetKu',
      'schemaVersion': schemaVersion,
      'exportedAt': (exportedAt ?? _clock().toUtc()).toIso8601String(),
      'counts': {
        'categories': categories.length,
        'transactions': transactions.length,
        'budgets': budgets.length,
      },
      'categories': [for (final item in categories) item.toMap()],
      'transactions': [for (final item in transactions) item.toMap()],
      'budgets': [for (final item in budgets) item.toMap()],
    };
  }

  Future<String> exportJson() async {
    final payload = await buildPayload();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<LocalDataExport> createExport() async {
    final exportedAt = _clock().toUtc();
    final payload = await buildPayload(exportedAt: exportedAt);
    return LocalDataExport(
      json: const JsonEncoder.withIndent('  ').convert(payload),
      exportedAt: exportedAt,
    );
  }
}

class LocalDataExport {
  const LocalDataExport({required this.json, required this.exportedAt});

  final String json;
  final DateTime exportedAt;
}
