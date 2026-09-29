import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/dashboard/services/expense_breakdown_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 28);
  CategoryModel category(int id, String name) => CategoryModel(
    id: id, name: name, type: TransactionType.expense, iconKey: 'more_horiz',
    colorValue: 0xFF0F766E, isDefault: false, isFavorite: false, sortOrder: id,
    isArchived: false, createdAt: now, updatedAt: now,
  );

  test('orders expenses descending and calculates exact proportions', () {
    final result = const ExpenseBreakdownService().build(
      {1: 100, 2: 600, 3: 300},
      [category(1, 'A'), category(2, 'B'), category(3, 'C')],
    );
    expect(result.map((slice) => slice.categoryId).toList(), [2, 3, 1]);
    expect(result.map((slice) => slice.percent).toList(), [60, 30, 10]);
  });

  test('zero total produces no percentages', () {
    expect(const ExpenseBreakdownService().build({}, []), isEmpty);
    expect(const ExpenseBreakdownService().build({1: 0}, []), isEmpty);
  });
}
