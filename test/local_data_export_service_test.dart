import 'dart:convert';

import 'package:dompetku_app/core/services/local_data_export_service.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCategoryRepository implements CategoryRepository {
  int calls = 0;
  Map<Symbol, dynamic>? lastArgs;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    lastArgs = invocation.namedArguments;
    return Future<List<CategoryModel>>.value(<CategoryModel>[]);
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    return Future<List<TransactionModel>>.value(<TransactionModel>[]);
  }
}

class _FakeBudgetRepository implements BudgetRepository {
  int calls = 0;
  Map<Symbol, dynamic>? lastArgs;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    lastArgs = invocation.namedArguments;
    return Future<List<BudgetModel>>.value(<BudgetModel>[]);
  }
}

void main() {
  late _FakeCategoryRepository categories;
  late _FakeTransactionRepository transactions;
  late _FakeBudgetRepository budgets;
  late LocalDataExportService service;

  setUp(() {
    categories = _FakeCategoryRepository();
    transactions = _FakeTransactionRepository();
    budgets = _FakeBudgetRepository();
    service = LocalDataExportService(
      categories,
      transactions,
      budgets,
      clock: () => DateTime.utc(2026, 9, 30, 8, 0),
    );
  });

  test('payload memuat metadata dan jumlah data', () async {
    final payload = await service.buildPayload();

    expect(payload['app'], 'DompetKu');
    expect(payload['schemaVersion'], LocalDataExportService.schemaVersion);
    expect(payload['exportedAt'], '2026-09-30T08:00:00.000Z');
    expect(payload['counts'], {
      'categories': 0,
      'transactions': 0,
      'budgets': 0,
    });
    expect(payload['categories'], isEmpty);
    expect(payload['transactions'], isEmpty);
    expect(payload['budgets'], isEmpty);
  });

  test('kategori dan anggaran diekspor termasuk yang diarsipkan', () async {
    await service.buildPayload();

    expect(categories.lastArgs?[#includeArchived], true);
    expect(budgets.lastArgs?[#includeArchived], true);
    expect(categories.calls, 1);
    expect(transactions.calls, 1);
    expect(budgets.calls, 1);
  });

  test('exportJson menghasilkan JSON valid', () async {
    final json = await service.exportJson();
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['app'], 'DompetKu');
    expect(decoded['categories'], isA<List<dynamic>>());
    expect(decoded['transactions'], isA<List<dynamic>>());
    expect(decoded['budgets'], isA<List<dynamic>>());
  });
}
