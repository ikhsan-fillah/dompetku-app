import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/models/budget_view_model.dart';
import 'package:dompetku_app/features/budget/services/budget_list_service.dart';
import 'package:flutter_test/flutter_test.dart';

BudgetViewModel _budget(int id, String name, int limit, int used) {
  final date = DateTime(2026, 9, 1);
  return BudgetViewModel(
    budget: BudgetModel(
      id: id,
      name: name,
      amountLimit: limit,
      categoryId: id,
      startDate: date,
      endDate: DateTime(2026, 9, 30),
      isArchived: false,
      createdAt: date,
      updatedAt: date,
    ),
    used: used,
  );
}

void main() {
  const service = BudgetListService();
  final items = [
    _budget(1, 'Makanan', 100, 90),
    _budget(2, 'Transportasi', 200, 50),
    _budget(3, 'Belanja', 150, 90),
  ];

  test('mengurutkan seluruh opsi budget', () {
    List<int> ids(BudgetSort sort) => service
        .sort(items, sort)
        .map((item) => item.budget.id!)
        .toList();

    expect(ids(BudgetSort.persentaseTerpakaiTertinggi), [1, 3, 2]);
    expect(ids(BudgetSort.sisaTerkecil), [1, 3, 2]);
    expect(ids(BudgetSort.limitTerbesar), [2, 3, 1]);
    expect(ids(BudgetSort.namaAZ), [3, 1, 2]);
  });
}