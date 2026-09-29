import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/models/spending_trend_point.dart';
import '../../dashboard/widgets/expense_donut.dart';
import '../widgets/home_app_bar.dart';

/// Isi tab Beranda. Data dimuat ulang otomatis; tidak ada tombol refresh.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (!auth.isUnlocked.value) {
        return Center(
          child: AppButton(
            label: 'Buka dengan biometrik',
            icon: Icons.fingerprint_rounded,
            expand: false,
            onPressed: () => Get.offAllNamed(AppRoutes.biometricUnlock),
          ),
        );
      }
      final controller = Get.find<DashboardController>();
      return Column(
        children: [
          const HomeAppBar(),
          Expanded(
            child: Obx(() {
              final state = controller.state.value;
              if (state.status == ResourceStatus.idle ||
                  state.status == ResourceStatus.loading) {
                return const AppLoadingView();
              }
              if (state.status == ResourceStatus.error) {
                return AppErrorView(
                  message: state.message ?? 'Gagal memuat dashboard.',
                  onRetry: () => controller.refreshDashboard(),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  4,
                  AppSpacing.page,
                  130,
                ),
                children: [
                  if (state.status == ResourceStatus.empty)
                    const AppEmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada transaksi',
                      message: 'Tidak ada transaksi pada periode yang dipilih.',
                    )
                  else if (state.data != null) ...[
                    _BalanceCard(data: state.data!),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Pengeluaran per kategori'),
                          ExpenseDonut(slices: state.data!.expenses),
                        ],
                      ),
                    ),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Tren pengeluaran'),
                          _TrendBars(points: state.data!.trend),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      );
    });
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

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.points});

  final List<SpendingTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('Belum ada pengeluaran pada periode ini.');
    }
    final visible =
        points.length > 10 ? points.sublist(points.length - 10) : points;
    final maxAmount =
        visible.fold<int>(0, (m, p) => p.amount > m ? p.amount : m);
    return Column(
      children: [
        for (final point in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${point.date.day}/${point.date.month}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: AppProgressBar(
                        value: maxAmount == 0 ? 0 : point.amount / maxAmount,
                        height: 12,
                        gradient: const LinearGradient(
                          colors: [AppColors.amber, AppColors.coral],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 46, top: 3),
                  child: Text(
                    formatIdr(point.amount),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
