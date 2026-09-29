import '../../../core/utils/budget_status.dart';

/// Ringkasan pemakaian satu anggaran pada periodenya.
class BudgetProgressModel {
  const BudgetProgressModel({
    required this.name,
    required this.limit,
    required this.used,
    required this.elapsedDays,
    required this.totalDays,
  });

  final String name;
  final int limit;
  final int used;
  final int elapsedDays;
  final int totalDays;

  /// Bisa negatif bila pengeluaran melewati batas.
  int get remaining => limit - used;

  double get percent => BudgetStatus.percentUsed(used: used, limit: limit);

  BudgetLevel get level => BudgetStatus.levelFor(percent);
}
