import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/budget_status.dart';

extension BudgetLevelStyle on BudgetLevel {
  String get label => switch (this) {
        BudgetLevel.safe => 'Aman',
        BudgetLevel.warning => 'Waspada',
        BudgetLevel.critical => 'Kritis',
        BudgetLevel.exceeded => 'Habis',
      };

  Color get foreground => switch (this) {
        BudgetLevel.safe => AppColors.teal,
        BudgetLevel.warning => AppColors.amberDeep,
        BudgetLevel.critical => const Color(0xFFC2410C),
        BudgetLevel.exceeded => AppColors.coral,
      };

  Color get background => switch (this) {
        BudgetLevel.safe => AppColors.mint,
        BudgetLevel.warning => AppColors.amberSoft,
        BudgetLevel.critical => AppColors.orangeSoft,
        BudgetLevel.exceeded => AppColors.coralSoft,
      };

  LinearGradient get gradient => switch (this) {
        BudgetLevel.safe => const LinearGradient(
            colors: [AppColors.tealLight, AppColors.emerald],
          ),
        BudgetLevel.warning => const LinearGradient(
            colors: [Color(0xFFFBBF24), AppColors.amber],
          ),
        BudgetLevel.critical => const LinearGradient(
            colors: [Color(0xFFFB923C), AppColors.orange],
          ),
        BudgetLevel.exceeded => const LinearGradient(
            colors: [Color(0xFFFB7185), AppColors.coral],
          ),
      };
}
