import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
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

  group('widget donat pengeluaran', () {
    CategoryModel category(int id, String name, int color) => CategoryModel(
      id: id,
      name: name,
      type: TransactionType.expense,
      iconKey: 'tag',
      colorValue: color,
      isDefault: false,
      isFavorite: false,
      sortOrder: id,
      isArchived: false,
      createdAt: _now,
      updatedAt: _now,
    );

    final categories = {
      1: category(1, 'Makan', 0xFFC4892A),
      2: category(2, 'Transport', 0xFF3F7A9E),
      3: category(3, 'Belanja', 0xFF8A5A3B),
    };

    test('total ringkas, 3 teratas dengan persen, potongan urut terbesar', () {
      final snapshot = WidgetSnapshot.build(
        transactions: [
          _tx(600000, DateTime(2026, 10, 2), categoryId: 1),
          _tx(300000, DateTime(2026, 10, 3), categoryId: 2),
          _tx(100000, DateTime(2026, 10, 4), categoryId: 3),
          _tx(5000000, DateTime(2026, 10, 1), type: TransactionType.income),
          _tx(999999, DateTime(2026, 9, 30), categoryId: 3),
        ],
        budgets: const [],
        now: _now,
        hideAmounts: false,
        categories: categories,
      );

      expect(snapshot.values['cat_total'], '1 jt');
      expect(snapshot.values['cat_name1'], 'Makan 60%');
      expect(snapshot.values['cat_name2'], 'Transport 30%');
      expect(snapshot.values['cat_name3'], 'Belanja 10%');
      expect(
        snapshot.categorySlices,
        'FFC4892A:0.6000;FF3F7A9E:0.3000;FF8A5A3B:0.1000',
      );
    });

    test('nominal disamarkan, bulan kosong menulis keterangan', () {
      final hidden = WidgetSnapshot.build(
        transactions: [_tx(250000, DateTime(2026, 10, 2))],
        budgets: const [],
        now: _now,
        hideAmounts: true,
        categories: categories,
      );
      expect(hidden.values['cat_total'], '••••');
      expect(hidden.values['cat_name1'], 'Makan 100%');

      final empty = WidgetSnapshot.build(
        transactions: const [],
        budgets: const [],
        now: _now,
        hideAmounts: false,
      );
      expect(empty.values['cat_total'], '');
      expect(empty.values['cat_caption'], 'Belum ada pengeluaran');
      expect(empty.values['cat_name1'], '');
      expect(empty.categorySlices, '');
    });

    test('lebih dari 5 kategori: sisanya digabung jadi abu', () {
      final snapshot = WidgetSnapshot.build(
        transactions: [
          for (var i = 1; i <= 7; i++)
            _tx(1000 * (8 - i), DateTime(2026, 10, 2), categoryId: i),
        ],
        budgets: const [],
        now: _now,
        hideAmounts: false,
      );
      final parts = snapshot.categorySlices.split(';');
      expect(parts, hasLength(6));
      expect(parts.last, startsWith('FF8A8F8B:'));
    });

    test('format ringkas', () {
      expect(WidgetSnapshot.compact(850000), '850 rb');
      expect(WidgetSnapshot.compact(1580000), '1,58 jt');
      expect(WidgetSnapshot.compact(2000000), '2 jt');
      expect(WidgetSnapshot.compact(2100000000), '2,1 M');
      expect(WidgetSnapshot.compact(900), '900');
    });
  });
}
