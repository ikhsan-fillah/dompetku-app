import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/services/category_detail_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 3, 31);

CategoryModel _category() => CategoryModel(
  id: 1,
  name: 'Makanan',
  type: TransactionType.expense,
  iconKey: 'restaurant',
  colorValue: 0xFFE57373,
  isDefault: false,
  isFavorite: false,
  sortOrder: 1,
  isArchived: false,
  createdAt: _now,
  updatedAt: _now,
);

TransactionModel _tx(int id, int amount, DateTime date) => TransactionModel(
  id: id,
  type: TransactionType.expense,
  title: 'Makan $id',
  amount: amount,
  transactionDate: date,
  categoryId: 1,
  createdAt: date,
  updatedAt: date,
);

void main() {
  const service = CategoryDetailService();

  test('menghitung total, rata-rata, persen, dan perubahan periode', () {
    final data = service.build(
      categoryId: 1,
      range: DateRange(start: DateTime(2026, 3, 1), end: _now),
      categories: [_category()],
      transactions: [
        _tx(1, 100, DateTime(2026, 2, 28)),
        _tx(2, 200, DateTime(2026, 3, 1)),
        _tx(3, 300, DateTime(2026, 3, 31)),
        _tx(4, 100, DateTime(2026, 3, 15)),
      ],
    );

    expect(data.total, 600);
    expect(data.transactionCount, 3);
    expect(data.average, 200);
    expect(data.percentOfExpenses, 100);
    expect(data.previousTotal, 100);
    expect(data.changePercent, 500);
  });

  test('periode Februari dan kategori tanpa transaksi tetap aman', () {
    final data = service.build(
      categoryId: 99,
      range: DateRange(start: DateTime(2024, 2, 1), end: DateTime(2024, 2, 29)),
      categories: const [],
      transactions: const [],
    );

    expect(data.total, 0);
    expect(data.average, 0);
    expect(data.percentOfExpenses, 0);
    expect(data.category, isNull);
  });
}