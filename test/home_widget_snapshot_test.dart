import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/widget/home_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 22, 14, 38);

TransactionModel _tx(
  int amount,
  DateTime date, {
  TransactionType type = TransactionType.expense,
  int categoryId = 1,
}) => TransactionModel(
  type: type,
  title: 'T',
  amount: amount,
  transactionDate: date,
  categoryId: categoryId,
  createdAt: date,
  updatedAt: date,
);

BudgetModel _budget(int limit, {int? categoryId = 1, bool archived = false}) =>
    BudgetModel(
      name: 'Makan',
      amountLimit: limit,
      categoryId: categoryId,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
      isArchived: archived,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  final transactions = [
    _tx(5000000, DateTime(2026, 10, 1), type: TransactionType.income),
    _tx(1000000, DateTime(2026, 10, 3)),
    _tx(580000, DateTime(2026, 10, 12), categoryId: 2),
    _tx(999999, DateTime(2026, 9, 30)),
  ];

  test('saldo bulan ini dan anggaran terpakai', () {
    final snapshot = WidgetSnapshot.build(
      transactions: transactions,
      budgets: [_budget(2000000)],
      now: _now,
      hideAmounts: false,
    );

    expect(snapshot.values['balance'], 'Rp 3.420.000');
    expect(snapshot.values['income'], '+ 5.000.000');
    expect(snapshot.values['expense'], '− 1.580.000');
    expect(snapshot.values['budget_percent'], '50%');
    expect(snapshot.budgetProgress, 50);
    expect(snapshot.values['budget_left'], 'sisa 1.000.000');
    expect(snapshot.values['updated'], '14.38');
  });

  test('sembunyikan nominal menyamarkan semua angka uang', () {
    final snapshot = WidgetSnapshot.build(
      transactions: transactions,
      budgets: [_budget(2000000)],
      now: _now,
      hideAmounts: true,
    );

    expect(snapshot.values['balance'], WidgetSnapshot.hidden);
    expect(snapshot.values['income'], '+ ••••');
    expect(snapshot.values['budget_left'], 'sisa ••••');
    // Persen tetap tampil karena bukan nominal.
    expect(snapshot.values['budget_percent'], '50%');
  });

  test('tanpa anggaran aktif menampilkan keterangan, bukan 0%', () {
    final snapshot = WidgetSnapshot.build(
      transactions: transactions,
      budgets: [_budget(2000000, archived: true)],
      now: _now,
      hideAmounts: false,
    );

    expect(snapshot.values['budget_percent'], '–');
    expect(snapshot.values['budget_caption'], 'belum ada anggaran');
    expect(snapshot.budgetProgress, 0);
  });

  test('anggaran terlewati: progres mentok 100, keterangan lewat', () {
    final snapshot = WidgetSnapshot.build(
      transactions: transactions,
      budgets: [_budget(500000)],
      now: _now,
      hideAmounts: false,
    );

    expect(snapshot.values['budget_percent'], '200%');
    expect(snapshot.budgetProgress, 100);
    expect(snapshot.values['budget_left'], 'lewat 500.000');
  });

  test('alamat tombol widget dipetakan ke aksi', () {
    expect(
      HomeWidgetService.actionFor(Uri.parse('tally://catat/expense')),
      WidgetAction.addExpense,
    );
    expect(
      HomeWidgetService.actionFor(Uri.parse('tally://catat/income')),
      WidgetAction.addIncome,
    );
    expect(
      HomeWidgetService.actionFor(Uri.parse('tally://anggaran')),
      WidgetAction.openBudget,
    );
    expect(
      HomeWidgetService.actionFor(Uri.parse('tally://open')),
      WidgetAction.open,
    );
    expect(HomeWidgetService.actionFor(Uri.parse('https://x.id')), isNull);
    expect(HomeWidgetService.actionFor(null), isNull);
  });
}
