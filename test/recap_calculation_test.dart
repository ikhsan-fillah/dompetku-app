import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/recap/services/recap_calculation_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionModel _tx(
  TransactionType type,
  int amount,
  DateTime date, {
  String title = 'x',
  int categoryId = 1,
}) => TransactionModel(
  type: type,
  title: title,
  amount: amount,
  transactionDate: date,
  categoryId: categoryId,
  createdAt: date,
  updatedAt: date,
);

void main() {
  const service = RecapCalculationService(FinancialCalculationService());

  final sept = [
    _tx(TransactionType.expense, 100000, DateTime(2026, 9, 3)),
    _tx(TransactionType.expense, 50000, DateTime(2026, 9, 10)),
    _tx(TransactionType.income, 5000000, DateTime(2026, 9, 1)),
  ];

  test('total pengeluaran bulanan sama dengan kalkulasi Beranda', () {
    final recap = service.monthly(
      sept,
      year: 2026,
      month: 9,
      now: DateTime(2026, 10, 1),
    );

    expect(recap.spent, 150000);
    expect(recap.income, 5000000);
    expect(recap.net, 4850000);
    expect(
      recap.spent,
      const FinancialCalculationService().totalForType(
        sept,
        TransactionType.expense,
        DateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
      ),
    );
  });

  test('bulan tanpa transaksi punya hasil kosong dan tidak meledak', () {
    final recap = service.monthly(
      sept,
      year: 2026,
      month: 8,
      now: DateTime(2026, 10, 1),
    );

    expect(recap.hasData, isFalse);
    expect(recap.spent, 0);
    expect(recap.dailyAverage, 0);
  });

  test('bulan berjalan diberi label so far', () {
    final recap = service.monthly(
      sept,
      year: 2026,
      month: 9,
      now: DateTime(2026, 9, 15),
    );

    expect(recap.isSoFar, isTrue);
  });

  test('rata-rata harian memakai jumlah hari di bulan itu', () {
    final recap = service.monthly(
      sept,
      year: 2026,
      month: 9,
      now: DateTime(2026, 10, 1),
    );

    expect(recap.dailyAverage, 5000);
  });

  test('bulan 31 hari menghitung hari dengan benar', () {
    final recap = service.monthly(
      sept,
      year: 2026,
      month: 10,
      now: DateTime(2026, 11, 1),
    );

    expect(recap.daysInMonth, 31);
  });

  test('recap tahunan menjumlahkan bulan yang punya transaksi', () {
    final list = [
      ...sept,
      _tx(TransactionType.expense, 200000, DateTime(2026, 3, 2)),
    ];
    final yearly = service.yearly(list, year: 2026, now: DateTime(2026, 10, 1));

    expect(yearly.totalSpent, 350000);
    expect(yearly.activeMonths, 2);
    expect(yearly.heaviestMonth, 3);
  });

  test('tahun masa depan tidak punya bulan', () {
    final yearly = service.yearly(sept, year: 2027, now: DateTime(2026, 10, 1));

    expect(yearly.activeMonths, 0);
    expect(yearly.monthsSoFar, 0);
  });

  test('recap menghitung pengeluaran per kategori dan urutan teratas', () {
    final list = [
      _tx(TransactionType.expense, 100000, DateTime(2026, 9, 3), categoryId: 1),
      _tx(TransactionType.expense, 300000, DateTime(2026, 9, 4), categoryId: 2),
      _tx(TransactionType.expense, 50000, DateTime(2026, 9, 5), categoryId: 2),
    ];
    final recap = service.monthly(
      list,
      year: 2026,
      month: 9,
      now: DateTime(2026, 10, 1),
    );

    expect(recap.topCategories.first.categoryId, 2);
    expect(recap.topCategories.first.total, 350000);
  });
}
