import '../../category/models/category_model.dart';
import 'expense_slice.dart';

class ExpenseBreakdownService {
  const ExpenseBreakdownService();

  List<ExpenseSlice> build(Map<int, int> totals, List<CategoryModel> categories) {
    final amount = totals.values.fold<int>(0, (sum, item) => sum + item);
    if (amount <= 0) return const [];
    final lookup = {for (final category in categories) if (category.id != null) category.id!: category};
    final sorted = totals.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) {
        final result = b.value.compareTo(a.value);
        return result != 0 ? result : a.key.compareTo(b.key);
      });
    return [
      for (final entry in sorted)
        ExpenseSlice(
          categoryId: entry.key,
          name: lookup[entry.key]?.name ?? 'Kategori #${entry.key}',
          colorValue: lookup[entry.key]?.colorValue ?? 0xFF64748B,
          amount: entry.value,
          percent: entry.value * 100 / amount,
        ),
    ];
  }
}
