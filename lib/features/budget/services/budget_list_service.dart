import '../models/budget_view_model.dart';

enum BudgetSort {
  persentaseTerpakaiTertinggi,
  sisaTerkecil,
  limitTerbesar,
  namaAZ,
}

class BudgetListService {
  const BudgetListService();

  List<BudgetViewModel> sort(
    Iterable<BudgetViewModel> items,
    BudgetSort order,
  ) {
    final result = items.toList();
    result.sort((a, b) {
      final value = switch (order) {
        BudgetSort.persentaseTerpakaiTertinggi => b.percent.compareTo(
          a.percent,
        ),
        BudgetSort.sisaTerkecil => a.remaining.compareTo(b.remaining),
        BudgetSort.limitTerbesar => b.budget.amountLimit.compareTo(
          a.budget.amountLimit,
        ),
        BudgetSort.namaAZ => a.budget.name.toLowerCase().compareTo(
          b.budget.name.toLowerCase(),
        ),
      };
      if (value != 0) return value;
      final date = b.budget.startDate.compareTo(a.budget.startDate);
      return date != 0 ? date : (b.budget.id ?? 0).compareTo(a.budget.id ?? 0);
    });
    return result;
  }
}
