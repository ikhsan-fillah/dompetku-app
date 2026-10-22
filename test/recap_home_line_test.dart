import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/recap/services/recap_calculation_service.dart';
import 'package:dompetku_app/features/recap/widgets/recap_home_line.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Tx implements TransactionRepository {
  _Tx(this.items);
  final List<TransactionModel> items;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Budgets implements BudgetRepository {
  @override
  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TransactionModel _tx(DateTime date, int amount) => TransactionModel(
  type: TransactionType.expense,
  title: 'x',
  amount: amount,
  transactionDate: date,
  categoryId: 1,
  createdAt: date,
  updatedAt: date,
);

Future<void> _pump(
  WidgetTester tester, {
  required DateTime now,
  required List<TransactionModel> tx,
}) async {
  Get.testMode = true;
  Get.reset();
  Get.put<TransactionRepository>(_Tx(tx));
  Get.put<BudgetRepository>(_Budgets());
  Get.put<CategoryRepository>(_Categories());
  Get.put(const RecapCalculationService(FinancialCalculationService()));
  await tester.pumpWidget(
    GetMaterialApp(
      home: Scaffold(body: RecapHomeLine(now: now)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => Get.reset());

  testWidgets('tampil di tanggal 2 jika bulan lalu punya transaksi', (
    tester,
  ) async {
    await _pump(
      tester,
      now: DateTime(2026, 10, 2),
      tx: [_tx(DateTime(2026, 9, 10), 50000)],
    );

    expect(find.text('Rekap September kamu sudah siap'), findsOneWidget);
  });

  testWidgets('tidak tampil di tanggal 4', (tester) async {
    await _pump(
      tester,
      now: DateTime(2026, 10, 4),
      tx: [_tx(DateTime(2026, 9, 10), 50000)],
    );

    expect(find.textContaining('sudah siap'), findsNothing);
  });

  testWidgets('tidak tampil jika bulan lalu kosong', (tester) async {
    await _pump(
      tester,
      now: DateTime(2026, 10, 1),
      tx: [_tx(DateTime(2026, 8, 10), 50000)],
    );

    expect(find.textContaining('sudah siap'), findsNothing);
  });

  testWidgets('bulan lalu di Januari menunjuk Desember tahun sebelumnya', (
    tester,
  ) async {
    await _pump(
      tester,
      now: DateTime(2026, 1, 2),
      tx: [_tx(DateTime(2025, 12, 20), 50000)],
    );

    expect(find.text('Rekap Desember kamu sudah siap'), findsOneWidget);
  });
}
