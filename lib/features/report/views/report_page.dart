import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../trend/widgets/income_trend_card.dart';
import '../controllers/report_controller.dart';
import '../widgets/report_visuals.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final controller = Get.find<ReportController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.loadMonth(DateTime.now()),
    );
  }

  String _money(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}Rp$buffer';
  }

  bool _isCurrentMonth(DateTime month) {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  void _shiftMonth(int delta) => controller.loadMonth(
    DateTime(controller.month.value.year, controller.month.value.month + delta),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          AppTitleBar(title: 'Laporan'.tr),
          const SizedBox(height: AppSpacing.gap),
          Obx(() {
            final month = controller.month.value;
            return MonthSwitcher(
              month: month,
              canGoNext: !_isCurrentMonth(month),
              onPrevious: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            );
          }),
          const SizedBox(height: AppSpacing.gap),
          Expanded(
            child: Obx(() {
              final current = controller.state.value;
              return switch (current.status) {
                ResourceStatus.idle || ResourceStatus.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.ink),
                ),
                ResourceStatus.empty => _Message(
                  icon: LucideIcons.chartColumn,
                  text: 'Belum ada transaksi pada bulan ini'.tr,
                  action: 'Muat ulang'.tr,
                  onTap: controller.reload,
                ),
                ResourceStatus.error => _Message(
                  icon: LucideIcons.circleAlert,
                  text: current.message ?? 'Gagal memuat laporan.'.tr,
                  action: 'Coba lagi'.tr,
                  onTap: controller.reload,
                ),
                ResourceStatus.success => RefreshIndicator(
                  color: AppColors.ink,
                  onRefresh: controller.reload,
                  child: _Summary(
                    data: current.data!,
                    start: controller.range.value.start,
                    isCurrentMonth: _isCurrentMonth(controller.month.value),
                    money: _money,
                  ),
                ),
              };
            }),
          ),
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.data,
    required this.start,
    required this.isCurrentMonth,
    required this.money,
  });

  final ReportData data;
  final DateTime start;
  final bool isCurrentMonth;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final remaining = summary.remainingBudget;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            children: [
              if (data.expensesByCategory.isEmpty || summary.expense == 0)
                SpendingRing(items: const [], total: 0, totalLabel: money(0))
              else
                SpendingRing(
                  items: data.expensesByCategory,
                  total: summary.expense,
                  totalLabel: money(summary.expense),
                ),
              const SizedBox(height: 16),
              _ChangeInsight(
                isEmptyMonth: data.isEmpty,
                change: data.expenseChange,
                hasPrevious: data.previousExpense > 0,
                isCurrentMonth: isCurrentMonth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Pemasukan vs pengeluaran'.tr,
          child: IncomeExpenseBars(
            income: summary.income,
            expense: summary.expense,
            money: money,
          ),
        ),
        if (data.incomeTrend != null) ...[
          const SizedBox(height: 14),
          IncomeTrendCard(
            key: ValueKey(data.incomeTrend!.month),
            trend: data.incomeTrend!,
          ),
        ],
        if (remaining != null) ...[
          const SizedBox(height: 14),
          _BudgetRemaining(value: money(remaining), negative: remaining < 0),
        ],
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Pengeluaran harian'.tr,
          child: DailySpendingBars(
            values: data.dailySpending,
            start: start,
            money: money,
          ),
        ),
        const SizedBox(height: 14),
        _SpendingStats(data: data, money: money),
        const SizedBox(height: 14),
        _CategoryBreakdown(
          items: data.expensesByCategory,
          total: summary.expense,
          money: money,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body(size: 13, weight: FontWeight.w700)),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _ChangeInsight extends StatelessWidget {
  const _ChangeInsight({
    required this.change,
    required this.hasPrevious,
    required this.isCurrentMonth,
    required this.isEmptyMonth,
  });

  final bool isEmptyMonth;
  final double change;
  final bool hasPrevious;
  final bool isCurrentMonth;

  String _message() {
    if (isEmptyMonth) return 'Belum ada transaksi pada bulan ini'.tr;
    if (!hasPrevious) {
      return 'Belum ada pengeluaran bulan lalu sebagai pembanding.'.tr;
    }
    final percent = (change.abs() * 100).round();
    final params = {'percent': '$percent'};
    if (change.abs() < 0.005) {
      return isCurrentMonth
          ? 'Pengeluaran sama dengan periode yang sama bulan lalu.'.tr
          : 'Pengeluaran sama dengan bulan lalu.'.tr;
    }
    if (change < 0) {
      return isCurrentMonth
          ? 'Pengeluaran turun @percent% dari periode yang sama bulan lalu.'
                .trParams(params)
          : 'Pengeluaran turun @percent% dari bulan lalu.'.trParams(params);
    }
    return isCurrentMonth
        ? 'Pengeluaran naik @percent% dari periode yang sama bulan lalu.'
              .trParams(params)
        : 'Pengeluaran naik @percent% dari bulan lalu.'.trParams(params);
  }

  @override
  Widget build(BuildContext context) {
    final neutral = isEmptyMonth || !hasPrevious || change.abs() < 0.005;
    final decreased = change < 0;
    final background = neutral
        ? AppColors.paper2
        : decreased
        ? AppColors.earnSoft
        : AppColors.spendSoft;
    final foreground = neutral
        ? AppColors.ink2
        : decreased
        ? AppColors.earn
        : AppColors.spend;
    final icon = neutral
        ? LucideIcons.minus
        : decreased
        ? LucideIcons.trendingDown
        : LucideIcons.trendingUp;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message(),
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetRemaining extends StatelessWidget {
  const _BudgetRemaining({required this.value, required this.negative});

  final String value;
  final bool negative;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: negative ? AppColors.spendSoft : AppColors.earnSoft,
            borderRadius: BorderRadius.circular(AppRadius.smallButton),
          ),
          child: Icon(
            LucideIcons.chartPie,
            size: 18,
            color: negative ? AppColors.spend : AppColors.earn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Sisa anggaran'.tr,
            style: AppText.body(size: 12, weight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: AppText.mono(
            size: 14,
            weight: FontWeight.w600,
            color: negative ? AppColors.spend : AppColors.earn,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

class _SpendingStats extends StatelessWidget {
  const _SpendingStats({required this.data, required this.money});

  final ReportData data;
  final String Function(int) money;

  String _dayLabel(DateTime value) =>
      '${value.day} ${AppLanguage.monthShort(value.month)} ${value.year}';

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Statistik pengeluaran'.tr,
    child: Column(
      children: [
        _StatRow(
          icon: LucideIcons.calculator,
          label: 'Rata-rata harian'.tr,
          value: '@amount / hari'.trParams({
            'amount': money(data.dailyAverage.round()),
          }),
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: LucideIcons.calendarX,
          label: 'Hari pengeluaran terbesar'.tr,
          value: data.highestSpendingDay == null
              ? '—'
              : '${_dayLabel(data.highestSpendingDay!)} · ${money(data.highestSpendingDayAmount)}',
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: LucideIcons.store,
          label: 'Merchant teratas'.tr,
          value: data.topMerchant == null
              ? '—'
              : '${data.topMerchant} · ${data.topMerchantCount}x',
        ),
      ],
    ),
  );
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(AppRadius.smallButton),
        ),
        child: Icon(icon, size: 17, color: AppColors.ink),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.body(size: 10.5, color: AppColors.mut)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono(
                size: 12.5,
                weight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.items,
    required this.total,
    required this.money,
  });

  final List<ReportCategoryTotal> items;
  final int total;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Rincian pengeluaran'.tr,
    child: Column(
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Belum ada pengeluaran pada bulan ini.'.tr,
                style: AppText.body(size: 12, color: AppColors.ink2),
              ),
            ),
          ),
        for (var index = 0; index < items.length; index++) ...[
          _CategoryRow(item: items[index], total: total, money: money),
          if (index < items.length - 1) const SizedBox(height: 14),
        ],
      ],
    ),
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.total,
    required this.money,
  });

  final ReportCategoryTotal item;
  final int total;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final share = total <= 0 ? 0.0 : item.amount / total;
    final color = Color(item.colorValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 12, weight: FontWeight.w600),
              ),
            ),
            Text(
              money(item.amount),
              style: AppText.mono(
                size: 12,
                weight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        AppProgressBar(value: share, color: color),
        const SizedBox(height: 5),
        Text(
          '@percent% dari pengeluaran'.trParams({
            'percent': '${(share * 100).round()}',
          }),
          style: AppText.body(size: 10.5, color: AppColors.mut),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String action;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: AppColors.ink),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.body(size: 13, color: AppColors.ink2),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: Text(
            action,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
