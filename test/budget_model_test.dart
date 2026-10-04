import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:flutter_test/flutter_test.dart';

BudgetModel _budget(DateTime start, DateTime end) => BudgetModel(
      id: 1,
      name: 'Anggaran tes',
      amountLimit: 1000000,
      categoryId: 2,
      note: null,
      startDate: start,
      endDate: end,
      isArchived: false,
      createdAt: start,
      updatedAt: start,
    );

void main() {
  test('round-trip mempertahankan tanggal awal dan akhir bulan', () {
    final source = _budget(DateTime(2026, 10, 1), DateTime(2026, 10, 30));
    final restored = BudgetModel.fromMap(source.toMap());

    expect(restored.startDate.year, 2026);
    expect(restored.startDate.month, 10);
    expect(restored.startDate.day, 1);
    expect(restored.endDate.day, 30);
  });

  test('round-trip mempertahankan periode lintas bulan', () {
    final source = _budget(DateTime(2026, 10, 28), DateTime(2026, 11, 3));
    final restored = BudgetModel.fromMap(source.toMap());

    expect(restored.startDate, DateTime(2026, 10, 28));
    expect(restored.endDate, DateTime(2026, 11, 3));
  });
}
