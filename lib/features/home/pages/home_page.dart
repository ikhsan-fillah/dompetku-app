import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/widgets/expense_donut.dart';
import '../../dashboard/widgets/spending_bars.dart';
import '../../shell/controllers/main_shell_controller.dart';
import '../widgets/budget_summary_cards.dart';
import '../widgets/category_cards_grid.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/insight_banner.dart';
import '../widgets/period_chips.dart';
import '../widgets/recent_transactions_card.dart';

/// Isi tab Beranda. Data dimuat ulang otomatis; tidak ada tombol refresh.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openTab(int index) {
    if (Get.isRegistered<MainShellController>()) {
      Get.find<MainShellController>().select(index);
    }
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    DashboardController controller,
  ) async {
    final current = controller.range.value;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: current.start, end: current.end),
    );
    if (picked != null) {
      await controller.setRange(
        DateRange(start: picked.start, end: picked.end),
      );
    }
  }

  List<Widget> _content(
    ResourceState<DashboardData> state,
    DashboardData? data,
    DashboardController controller,
  ) {
    switch (state.status) {
      case ResourceStatus.idle:
      case ResourceStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case ResourceStatus.error:
        return [
          AppErrorView(
            message: state.message ?? 'Gagal memuat dashboard.',
            onRetry: () => controller.refreshDashboard(),
          ),
        ];
      case ResourceStatus.empty:
        return const [
          AppEmptyView(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada transaksi',
            message:
                'Tidak ada transaksi pada periode yang dipilih. Coba pilih periode lain.',
          ),
        ];
      case ResourceStatus.success:
        if (data == null) return const [];
        return [
          BudgetSummaryCards(
            budget: data.budget,
            topCategory: data.expenses.isEmpty ? null : data.expenses.first,
            onSetupBudget: () => _openTab(2),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Pengeluaran per kategori'),
                ExpenseDonut(slices: data.expenses),
                const SizedBox(height: 8),
                const Text(
                  'Urut dari terbesar ke terkecil · ketuk untuk detail',
                  style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Tren pengeluaran'),
                SpendingBars(buckets: data.trendBuckets),
              ],
            ),
          ),
          if (data.favorites.isNotEmpty) ...[
            const SectionHeader(title: 'Kategori favorit'),
            CategoryCardsGrid(items: data.favorites),
          ],
          if (data.recent.isNotEmpty)
            RecentTransactionsCard(
              items: data.recent,
              onSeeAll: () => _openTab(1),
            ),
          if (data.insight != null)
            InsightBanner(message: data.insight!.message),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Column(
      children: [
        const HomeAppBar(),
        Expanded(
          child: Obx(() {
            final state = controller.state.value;
            final data = state.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                4,
                AppSpacing.page,
                130,
              ),
              children: [
                if (state.status == ResourceStatus.success && data != null) ...[
                  _BalanceCard(data: data),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Get.toNamed(AppRoutes.report),
                      icon: const Icon(Icons.bar_chart_rounded, size: 18),
                      label: const Text('Lihat laporan'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.teal,
                      ),
                    ),
                  ),
                ],
                PeriodChips(
                  selected: controller.preset.value,
                  onSelect: (preset) {
                    if (preset == DateRangePreset.custom) {
                      _pickCustomRange(context, controller);
                    } else {
                      controller.setPreset(preset);
                    }
                  },
                ),
                const _AutoRefreshHint(),
                ..._content(state, data, controller),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _AutoRefreshHint extends StatelessWidget {
  const _AutoRefreshHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12, left: 2),
      child: Row(
        children: [
          SizedBox(
            width: 7,
            height: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.emerald,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Diperbarui otomatis',
            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      gradient: AppColors.heroGradient,
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo periode ini',
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatIdr(summary.balance),
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniPill(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Pemasukan',
                  amount: summary.income,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniPill(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Pengeluaran',
                  amount: summary.expense,
                  color: AppColors.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatIdr(amount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
