import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../recap/widgets/recap_home_line.dart';
import '../../dashboard/models/dashboard_summary_model.dart';
import '../../dashboard/widgets/expense_donut.dart';
import '../../drafts/widgets/drafts_banner.dart';
import '../../shell/controllers/main_shell_controller.dart';
import '../../trend/widgets/spending_trend_card.dart';
import '../widgets/category_cards_grid.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/insight_banner.dart';
import '../widgets/recent_transactions_card.dart';

/// Isi tab Beranda. Data dimuat ulang otomatis; tidak ada tombol refresh.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openTab(int index) {
    if (Get.isRegistered<MainShellController>()) {
      Get.find<MainShellController>().select(index);
    }
  }

  /// Data yang ditampilkan: data asli atau data nol pada periode kosong.
  DashboardData? _displayData(
    ResourceState<DashboardData> state,
    DashboardController controller,
  ) {
    switch (state.status) {
      case ResourceStatus.success:
        return state.data;
      case ResourceStatus.empty:
        return const DashboardData(
          summary: DashboardSummaryModel(income: 0, expense: 0, balance: 0),
          trend: [],
          previousPeriodExpenseChange: 0,
          expenses: [],
        );
      case ResourceStatus.idle:
      case ResourceStatus.loading:
      case ResourceStatus.error:
        return null;
    }
  }

  List<Widget> _content(
    BuildContext context,
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
            message: state.message ?? 'Gagal memuat dashboard.'.tr,
            onRetry: () => controller.refreshDashboard(),
          ),
        ];
      case ResourceStatus.empty:
      case ResourceStatus.success:
        if (data == null) return const [];
        return [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Pengeluaran per kategori'.tr),
                ExpenseDonut(slices: data.expenses),
                if (data.expenses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Urut dari terbesar ke terkecil · ketuk untuk detail'.tr,
                    style: AppText.body(size: 10.5, color: AppColors.mut),
                  ),
                ],
              ],
            ),
          ),
          const SpendingTrendCard(),
          if (data.favorites.isNotEmpty) ...[
            SectionHeader(title: 'Kategori favorit'.tr),
            CategoryCardsGrid(
              items: data.favorites,
              onTap: (categoryId) => Get.toNamed(
                AppRoutes.categoryDetail,
                arguments: {'categoryId': categoryId},
              ),
            ),
          ],
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
            final data = _displayData(state, controller);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                4,
                AppSpacing.page,
                130,
              ),
              children: [
                if (data != null) ...[_BalanceCard(data: data)],
                const DraftsBanner(),
                const RecapHomeLine(),
                if (!controller.hasTransactionsInPeriod.value &&
                    controller.hasAnyTransactions.value)
                  const _EmptyPeriodNote(),
                ..._content(context, state, data, controller),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Catatan kecil bila periode terpilih kosong tetapi pengguna punya transaksi lain.
class _EmptyPeriodNote extends StatelessWidget {
  const _EmptyPeriodNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, size: 18, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tidak ada transaksi pada periode ini. Coba pilih periode lain.'
                  .tr,
              style: AppText.body(size: 12, color: AppColors.mut),
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gap),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo periode ini'.tr.toUpperCase(),
            style: AppText.body(
              size: 11.5,
              weight: FontWeight.w700,
              color: AppColors.paper.withValues(alpha: 0.7),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatIdrPlain(summary.balance),
              maxLines: 1,
              style: AppText.display(
                size: 38,
                color: AppColors.paper,
                height: 1.05,
                letterSpacing: -0.38,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.paper.withValues(alpha: 0.18)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniPill(
                    icon: LucideIcons.arrowUp,
                    label: 'Pemasukan'.tr,
                    amount: summary.income,
                    color: AppColors.earn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.paper.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    child: _MiniPill(
                      icon: LucideIcons.arrowDown,
                      label: 'Pengeluaran'.tr,
                      amount: summary.expense,
                      color: AppColors.spend,
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
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.paper, size: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.body(
                  size: 10,
                  color: AppColors.paper.withValues(alpha: 0.7),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatIdr(amount),
                  style: AppText.mono(size: 12.5, color: AppColors.paper),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
