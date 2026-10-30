import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/recap/services/recap_calculation_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _tx(
  TransactionType type,
  int amount,
  DateTime date, {
  int categoryId = 1,
  String? merchant,
}) => TransactionModel(
  type: type,
  title: merchant ?? 'x',
  amount: amount,
  transactionDate: date,
  categoryId: categoryId,
  merchantOrSource: merchant,
  createdAt: date,
  updatedAt: date,
);

BudgetModel _budget({
  int? categoryId,
  required int limit,
  required DateTime start,
  required DateTime end,
}) => BudgetModel(
  name: 'b',
  amountLimit: limit,
  categoryId: categoryId,
  startDate: start,
  endDate: end,
  isArchived: false,
  createdAt: start,
  updatedAt: start,
);

void main() {
  _decisionTests();
  const service = RecapCalculationService(FinancialCalculationService());
  final now = DateTime(2026, 10, 17);

  test('daily spend indexed by day and elapsed days capped at today', () {
    final list = [
      _tx(TransactionType.expense, 100000, DateTime(2026, 10, 3)),
      _tx(TransactionType.expense, 50000, DateTime(2026, 10, 3)),
    ];
    final recap = service.monthly(list, year: 2026, month: 10, now: now);

    expect(recap.dailySpend[2], 150000);
    expect(recap.elapsedDays, 17);
    expect(recap.isSoFar, isTrue);
    expect(recap.noSpendDays, 16);
    expect(recap.heaviestDay, 3);
  });

  test('future month has zero elapsed days and no average', () {
    final recap = service.monthly(const [], year: 2026, month: 12, now: now);

    expect(recap.elapsedDays, 0);
    expect(recap.dailyAverage, 0);
  });

  test('previous month comparison is null when previous month is empty', () {
    final list = [_tx(TransactionType.expense, 10000, DateTime(2026, 9, 5))];
    final oct = service.monthly(list, year: 2026, month: 10, now: now);
    final sep = service.monthly(list, year: 2026, month: 9, now: now);

    expect(oct.previousSpent, 10000);
    expect(sep.previousSpent, isNull);
  });

  test('merchants ranked by visits then total', () {
    final list = [
      _tx(
        TransactionType.expense,
        5000,
        DateTime(2026, 9, 1),
        merchant: 'Gojek',
      ),
      _tx(
        TransactionType.expense,
        5000,
        DateTime(2026, 9, 2),
        merchant: 'Gojek',
      ),
      _tx(
        TransactionType.expense,
        90000,
        DateTime(2026, 9, 3),
        merchant: 'Indomaret',
      ),
    ];
    final recap = service.monthly(list, year: 2026, month: 9, now: now);

    expect(recap.merchants.first.name, 'Gojek');
    expect(recap.merchants.first.visits, 2);
  });

  test('budget status uses overall budget against month spend', () {
    final list = [_tx(TransactionType.expense, 300000, DateTime(2026, 9, 5))];
    final budgets = [
      _budget(
        limit: 500000,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      ),
    ];
    final recap = service.monthly(
      list,
      year: 2026,
      month: 9,
      now: now,
      budgets: budgets,
    );

    expect(recap.overallBudget, 500000);
    expect(recap.budgetStatus, BudgetMonthStatus.inside);
  });

  test('budget month over limit is flagged over', () {
    final list = [_tx(TransactionType.expense, 600000, DateTime(2026, 9, 5))];
    final budgets = [
      _budget(
        limit: 500000,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      ),
    ];
    final recap = service.monthly(
      list,
      year: 2026,
      month: 9,
      now: now,
      budgets: budgets,
    );

    expect(recap.budgetStatus, BudgetMonthStatus.over);
  });

  test(
    'yearly recap picks heaviest, lightest, top merchant and budget months',
    () {
      final list = [
        _tx(
          TransactionType.expense,
          100000,
          DateTime(2026, 2, 1),
          merchant: 'Warung',
        ),
        _tx(
          TransactionType.expense,
          600000,
          DateTime(2026, 5, 1),
          merchant: 'Warung',
        ),
        _tx(TransactionType.income, 1000000, DateTime(2026, 5, 2)),
      ];
      final budgets = [
        _budget(
          limit: 500000,
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 12, 31),
        ),
      ];
      final yearly = service.yearly(
        list,
        year: 2026,
        now: now,
        budgets: budgets,
      );

      expect(yearly.heaviestMonth, 5);
      expect(yearly.lightestMonth, 2);
      expect(yearly.topMerchant!.name, 'Warung');
      expect(yearly.topMerchant!.visits, 2);
      expect(yearly.budgetMonthsWithData, 2);
      expect(yearly.budgetMonthsInside, 1);
      expect(yearly.net, 300000);
      expect(yearly.isSoFar, isTrue);
    },
  );
}

void _decisionTests() {
  const service = RecapCalculationService(FinancialCalculationService());
  final now = DateTime(2026, 11, 1);

  group('batas harian', () {
    test('total budget keseluruhan dibagi jumlah hari', () {
      final recap = service.monthly(
        [_tx(TransactionType.expense, 1000, DateTime(2026, 9, 3))],
        year: 2026,
        month: 9,
        now: now,
        budgets: [
          _budget(
            limit: 3000000,
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 30),
          ),
        ],
      );

      expect(recap.dailyLimit, 100000);
    });

    test('tanpa budget keseluruhan batas harian null', () {
      final recap = service.monthly(
        [_tx(TransactionType.expense, 1000, DateTime(2026, 9, 3))],
        year: 2026,
        month: 9,
        now: now,
      );

      expect(recap.dailyLimit, isNull);
    });

    test('hari di bawah batas dihitung', () {
      final recap = service.monthly(
        [
          _tx(TransactionType.expense, 50000, DateTime(2026, 9, 3)),
          _tx(TransactionType.expense, 200000, DateTime(2026, 9, 4)),
        ],
        year: 2026,
        month: 9,
        now: now,
        budgets: [
          _budget(
            limit: 3000000,
            start: DateTime(2026, 9, 1),
            end: DateTime(2026, 9, 30),
          ),
        ],
      );

      expect(recap.daysUnderLimit, 29);
    });
  });

  group('quiet streak', () {
    test(
      'hari tanpa catatan dihitung tanpa pengeluaran sejak transaksi pertama',
      () {
        final yearly = service.yearly(
          [
            _tx(TransactionType.expense, 1000, DateTime(2026, 9, 1)),
            _tx(TransactionType.expense, 1000, DateTime(2026, 9, 10)),
          ],
          year: 2026,
          now: DateTime(2026, 9, 15),
        );

        expect(yearly.quietStreak, 8);
        expect(yearly.quietDays, 13);
      },
    );

    test('hari sebelum transaksi pertama tidak dihitung', () {
      final yearly = service.yearly(
        [_tx(TransactionType.expense, 1000, DateTime(2026, 6, 1))],
        year: 2026,
        now: DateTime(2026, 6, 4),
      );

      expect(yearly.quietDays, 3);
    });

    test('tahun tanpa transaksi punya streak nol', () {
      final yearly = service.yearly(
        const [],
        year: 2026,
        now: DateTime(2026, 6, 4),
      );

      expect(yearly.quietStreak, 0);
      expect(yearly.quietDays, 0);
    });
  });

  group('pengeluaran tunggal terbesar', () {
    test('mengambil transaksi expense terbesar di tahun itu', () {
      final yearly = service.yearly(
        [
          _tx(
            TransactionType.expense,
            1000,
            DateTime(2026, 2, 1),
            merchant: 'A',
          ),
          _tx(
            TransactionType.expense,
            9000,
            DateTime(2026, 5, 1),
            merchant: 'B',
          ),
          _tx(TransactionType.income, 99999, DateTime(2026, 5, 2)),
        ],
        year: 2026,
        now: now,
      );

      expect(yearly.biggestExpense!.amount, 9000);
      expect(yearly.biggestExpense!.name, 'B');
    });

    test('tanpa pengeluaran hasilnya null', () {
      final yearly = service.yearly(const [], year: 2026, now: now);

      expect(yearly.biggestExpense, isNull);
    });
  });
}
