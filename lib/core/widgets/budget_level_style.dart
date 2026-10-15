import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/budget_status.dart';

/// Warna status anggaran (spec §3.24): Aman < 75, Waspada ≥ 75, Kritis ≥ 90, Habis ≥ 100.
extension BudgetLevelStyle on BudgetLevel {
  String get label => switch (this) {
    BudgetLevel.safe => 'Aman',
    BudgetLevel.warning => 'Waspada',
    BudgetLevel.critical => 'Kritis',
    BudgetLevel.exceeded => 'Habis',
  };

  Color get foreground => switch (this) {
    BudgetLevel.safe => AppColors.earn,
    BudgetLevel.warning => AppColors.warn,
    BudgetLevel.critical => AppColors.crit,
    BudgetLevel.exceeded => AppColors.spend,
  };

  Color get background => switch (this) {
    BudgetLevel.safe => AppColors.earnSoft,
    BudgetLevel.warning => AppColors.warnSoft,
    BudgetLevel.critical => AppColors.critSoft,
    BudgetLevel.exceeded => AppColors.spendSoft,
  };

  /// Warna solid untuk progress bar dan ring; sama dengan [foreground].
  Color get solid => foreground;
}
