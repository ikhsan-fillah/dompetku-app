enum BudgetLevel { safe, warning, critical, exceeded }

/// Aturan status anggaran yang dipakai bersama oleh Beranda, Anggaran, dan Laporan.
abstract final class BudgetStatus {
  static const int warningThreshold = 75;
  static const int criticalThreshold = 90;
  static const int exceededThreshold = 100;

  static double percentUsed({required int used, required int limit}) {
    if (limit <= 0) return 0;
    return used * 100 / limit;
  }

  static BudgetLevel levelFor(double percent) {
    if (percent >= exceededThreshold) return BudgetLevel.exceeded;
    if (percent >= criticalThreshold) return BudgetLevel.critical;
    if (percent >= warningThreshold) return BudgetLevel.warning;
    return BudgetLevel.safe;
  }
}
