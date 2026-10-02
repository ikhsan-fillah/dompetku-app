import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/budget_level_style.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../dashboard/models/budget_progress_model.dart';
import '../../dashboard/models/expense_slice.dart';
import '../../dashboard/widgets/budget_ring.dart';

/// Dua kartu berdampingan: anggaran bulanan dan kategori teratas.
class BudgetSummaryCards extends StatelessWidget {
  const BudgetSummaryCards({
    super.key,
    required this.budget,
    required this.topCategory,
    required this.onSetupBudget,
  });

  final BudgetProgressModel? budget;
  final ExpenseSlice? topCategory;
  final VoidCallback onSetupBudget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _BudgetCard(budget: budget, onSetup: onSetupBudget),
            ),
            const SizedBox(width: 12),
            Expanded(child: _TopCategoryCard(slice: topCategory)),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.onSetup});

  final BudgetProgressModel? budget;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final current = budget;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: current == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anggaran bulanan', style: titleStyle),
                const SizedBox(height: 12),
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 30,
                  color: AppColors.teal,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada anggaran',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Atur batas bulanan agar ritme belanjamu terpantau.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Atur',
                  kind: AppButtonKind.soft,
                  onPressed: onSetup,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Anggaran bulanan', style: titleStyle),
                ),
                const SizedBox(height: 10),
                BudgetRing(
                  percent: current.percent,
                  color: current.level.foreground,
                  size: 92,
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: current.level.label,
                  background: current.level.background,
                  foreground: current.level.foreground,
                ),
                const SizedBox(height: 6),
                Text(
                  'Hari ke-${current.elapsedDays} dari ${current.totalDays}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  current.remaining >= 0
                      ? 'Sisa ${formatIdr(current.remaining)}'
                      : 'Lewat ${formatIdr(-current.remaining)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: current.remaining >= 0
                        ? AppColors.ink
                        : AppColors.coral,
                  ),
                ),
              ],
            ),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  const _TopCategoryCard({required this.slice});

  final ExpenseSlice? slice;

  @override
  Widget build(BuildContext context) {
    final current = slice;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.amberSoft, Color(0xFFFFF7ED)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori teratas',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          if (current == null)
            const Text(
              'Belum ada data',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            )
          else ...[
            CategoryIconBox(
              icon: Icons.emoji_events_rounded,
              color: CategoryStyle.color(current.colorValue),
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              current.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              formatIdr(current.amount),
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            StatusPill(
              label: '${current.percent.round()}% dari pengeluaran',
              background: Colors.white,
              foreground: AppColors.amberDeep,
            ),
          ],
        ],
      ),
    );
  }
}
