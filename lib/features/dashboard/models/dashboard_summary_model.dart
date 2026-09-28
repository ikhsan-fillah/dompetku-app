class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.income,
    required this.expense,
    required this.balance,
    this.remainingBudget,
  });

  final int income;
  final int expense;
  final int balance;
  final int? remainingBudget;
}
