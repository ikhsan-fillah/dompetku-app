import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/services/transaction_list_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 29);
const _service = TransactionListService();

CategoryModel _cat(int id, String name) {
  return CategoryModel(
    id: id,
    name: name,
    type: TransactionType.expense,
    iconKey: 'restaurant',
    colorValue: 0xFFE57373,
    isDefault: false,
    isFavorite: false,
    sortOrder: id,
    isArchived: false,
    createdAt: _now,
    updatedAt: _now,
  );
}

TransactionModel _tx(
  int id,
  TransactionType type,
  int categoryId,
  int amount,
  DateTime date, {
  String title = 'T',
  String? note,
}) {
  return TransactionModel(
    id: id,
    type: type,
    title: title,
    amount: amount,
    transactionDate: date,
    categoryId: categoryId,
    note: note,
    createdAt: date,
    updatedAt: date,
  );
}

final _data = [
  _tx(1, TransactionType.expense, 1, 10, DateTime(2026, 9, 28, 9)),
  _tx(2, TransactionType.expense, 1, 20, DateTime(2026, 9, 28, 15)),
  _tx(3, TransactionType.income, 2, 500, DateTime(2026, 9, 25, 10)),
  _tx(
    4,
    TransactionType.expense,
    2,
    30,
    DateTime(2026, 9, 29, 8),
    title: 'Isi bensin',
    note: 'Pertalite',
  ),
];

void main() {
  final categories = [_cat(1, 'Makanan'), _cat(2, 'Transportasi')];

  test('dikelompokkan per hari dari terbaru dan menghitung total', () {
    final result = _service.build(transactions: _data, categories: categories);
    expect(result.groups.map((g) => g.date.day).toList(), [29, 28, 25]);
    expect(result.groups[1].items.map((i) => i.id).toList(), [2, 1]);
    expect(result.income, 500);
    expect(result.expense, 60);
  });

  test('filter jenis pengeluaran dan pemasukan', () {
    final expenses = _service.build(
      transactions: _data,
      categories: categories,
      filter: TransactionTypeFilter.expense,
    );
    expect(expenses.groups.expand((g) => g.items).length, 3);
    expect(expenses.income, 0);

    final incomes = _service.build(
      transactions: _data,
      categories: categories,
      filter: TransactionTypeFilter.income,
    );
    expect(incomes.groups.expand((g) => g.items).single.id, 3);
  });

  test('pencarian mencakup judul, catatan, dan nama kategori', () {
    List<int> ids(String query) =>
        _service
            .build(transactions: _data, categories: categories, query: query)
            .groups
            .expand((g) => g.items)
            .map((i) => i.id)
            .toList()
          ..sort();

    expect(ids('makanan'), [1, 2]);
    expect(ids('PERTALITE'), [4]);
    expect(ids('bensin'), [4]);
  });

  test('tanpa hasil menghasilkan hasil kosong', () {
    final result = _service.build(
      transactions: _data,
      categories: categories,
      query: 'tidak ada',
    );
    expect(result.isEmpty, isTrue);
    expect(result.expense, 0);
  });

  test('semua opsi sort menghasilkan urutan yang diharapkan dan stabil', () {
    List<int> ids(TransactionSort sort) => _service
        .build(transactions: _data, categories: categories, sort: sort)
        .items
        .map((item) => item.id)
        .toList();

    expect(ids(TransactionSort.nominalTerbesar), [3, 4, 2, 1]);
    expect(ids(TransactionSort.nominalTerkecil), [1, 2, 4, 3]);
    expect(ids(TransactionSort.namaAZ), [4, 2, 1, 3]);
    expect(ids(TransactionSort.namaZA), [2, 1, 3, 4]);
    expect(ids(TransactionSort.kategoriAZ), [2, 1, 4, 3]);
    final oldest = _service.build(
      transactions: _data,
      categories: categories,
      sort: TransactionSort.terlama,
    );
    expect(
      oldest.groups.expand((group) => group.items).map((item) => item.id),
      [3, 1, 2, 4],
    );

    final ties = [
      _tx(9, TransactionType.expense, 1, 10, DateTime(2026, 9, 20)),
      _tx(8, TransactionType.expense, 1, 10, DateTime(2026, 9, 21)),
    ];
    final result = _service.build(
      transactions: ties,
      categories: categories,
      sort: TransactionSort.nominalTerbesar,
    );
    expect(result.items.map((item) => item.id), [8, 9]);
  });
}
