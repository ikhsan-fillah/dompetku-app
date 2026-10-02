import '../../../core/utils/budget_status.dart';
import 'budget_model.dart';

/// Model siap-tampil untuk daftar anggaran.
class BudgetViewModel {
  const BudgetViewModel({required this.budget, required this.used});

  final BudgetModel budget;
  final int used;

  int get remaining => budget.amountLimit - used;

  double get percent =>
      BudgetStatus.percentUsed(used: used, limit: budget.amountLimit);

  BudgetLevel get level => BudgetStatus.levelFor(percent);

  bool get isOverall => budget.categoryId == null;
}
