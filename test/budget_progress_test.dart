import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/budget_status.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 29, 12);
const _service = FinancialCalculationService();

TransactionModel _tx(
  int amount, {
  TransactionType type = TransactionType.expense,
  int categoryId = 1,
  DateTime? date,
}) {
  final at = date ?? DateTime(2026, 9, 10);
  return TransactionModel(
    type: type,
    title: 'T',
    amount: amount,
    transactionDate: at,
    categoryId: categoryId,
    createdAt: at,
    updatedAt: at,
  );
}

BudgetModel _budget({
  int limit = 5000000,
  int? categoryId,
  DateTime? start,
  DateTime? end,
  bool archived = false,
}) {
  return BudgetModel(
    id: 1,
    name: 'September',
    amountLimit: limit,
    categoryId: categoryId,
    startDate: start ?? DateTime(2026, 9, 1),
    endDate: end ?? DateTime(2026, 9, 30),
    isArchived: archived,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  group('budgetProgress', () {
    test('menghitung pemakaian, persen, status, dan hari berjalan', () {
      final progress = _service.budgetProgress(
        [
          _tx(3650000),
          _tx(1000000, type: TransactionType.income),
          _tx(999999, date: DateTime(2026, 8, 31)),
        ],
        _budget(),
        now: _now,
      );
      expect(progress.used, 3650000);
      expect(progress.percent, 73);
      expect(progress.level, BudgetLevel.safe);
      expect(progress.remaining, 1350000);
      expect(progress.elapsedDays, 29);
      expect(progress.totalDays, 30);
    });

    test('anggaran kategori hanya menghitung kategori itu', () {
      final progress = _service.budgetProgress(
        [_tx(400000, categoryId: 1), _tx(600000, categoryId: 2)],
        _budget(limit: 1000000, categoryId: 2),
        now: _now,
      );
      expect(progress.used, 600000);
      expect(progress.level, BudgetLevel.warning);
    });

    test('melewati batas menjadi habis dengan sisa negatif', () {
      final progress = _service.budgetProgress(
        [_tx(1200000)],
        _budget(limit: 1000000),
        now: _now,
      );
      expect(progress.level, BudgetLevel.exceeded);
      expect(progress.remaining, -200000);
    });

    test('tanggal anggaran yang tersimpan dalam UTC dibaca sebagai hari lokal',
        () {
      final progress = _service.budgetProgress(
        [_tx(100000)],
        _budget(
          start: DateTime(2026, 9, 1).toUtc(),
          end: DateTime(2026, 9, 30).toUtc(),
        ),
        now: _now,
      );
      expect(progress.totalDays, 30);
      expect(progress.used, 100000);
    });
  });

  group('activeOverallBudget', () {
    test('memilih anggaran keseluruhan yang berlaku', () {
      final active = _service.activeOverallBudget(
        [
          _budget(categoryId: 3),
          _budget(archived: true),
          _budget(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31)),
          _budget(limit: 777),
        ],
        now: _now,
      );
      expect(active, isNotNull);
      expect(active!.amountLimit, 777);
    });

    test('tidak ada anggaran berlaku menghasilkan null', () {
      expect(
        _service.activeOverallBudget(
          [_budget(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31))],
          now: _now,
        ),
        isNull,
      );
    });
  });
}
