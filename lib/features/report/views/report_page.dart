import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../controllers/report_controller.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

class _ReportPageState extends State<ReportPage> {
  static const _presets = <(DateRangePreset, String)>[
    (DateRangePreset.today, 'Hari ini'),
    (DateRangePreset.week, '1 Minggu'),
    (DateRangePreset.month, '1 Bulan'),
    (DateRangePreset.threeMonths, '3 Bulan'),
    (DateRangePreset.yearToDate, 'Tahun ini'),
    (DateRangePreset.year, '1 Tahun'),
    (DateRangePreset.allTime, 'Semua'),
    (DateRangePreset.currentMonth, 'Bulan ini'),
    (DateRangePreset.custom, 'Kustom'),
  ];

  final controller = Get.find<ReportController>();
  DateRangePreset _preset = DateRangePreset.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.load(DateRange.fromPreset(_preset)),
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

  String _date(DateTime value) =>
      '${value.day} ${_months[value.month - 1]} ${value.year}';

  Future<void> _selectPreset(DateRangePreset preset) async {
    if (preset == DateRangePreset.custom) {
      await _pickCustom();
      return;
    }
    setState(() => _preset = preset);
    await controller.load(DateRange.fromPreset(preset));
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(2000);
    final current = controller.range.value;
    final start = current.start.isBefore(first) ? first : current.start;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today,
      initialDateRange: DateTimeRange(start: start, end: current.end),
    );
    if (picked == null || !mounted) return;
    setState(() => _preset = DateRangePreset.custom);
    await controller.load(
      DateRange.history(start: picked.start, end: picked.end),
    );
  }

  Future<void> _reload() => controller.load(controller.range.value);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const AppTitleBar(title: 'Laporan'),
          const SizedBox(height: AppSpacing.gap),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
                vertical: 6,
              ),
              itemCount: _presets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final (preset, label) = _presets[index];
                final selected = preset == _preset;
                return AppChip(
                  label: label,
                  selected: selected,
                  onTap: () => _selectPreset(preset),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.tight,
              AppSpacing.page,
              AppSpacing.gap,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Obx(() {
                final range = controller.range.value;
                return Text(
                  '${_date(range.start)} - ${_date(range.end)}',
                  style: AppText.mono(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppColors.mut,
                    letterSpacing: 0,
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Obx(() {
              final current = controller.state.value;
              return switch (current.status) {
                ResourceStatus.idle || ResourceStatus.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.ink),
                ),
                ResourceStatus.empty => _Message(
                  icon: LucideIcons.chartColumn,
                  text: 'Belum ada transaksi pada periode ini',
                  action: 'Muat ulang',
                  onTap: _reload,
                ),
                ResourceStatus.error => _Message(
                  icon: LucideIcons.circleAlert,
                  text: current.message ?? 'Gagal memuat laporan.',
                  action: 'Coba lagi',
                  onTap: _reload,
                ),
                ResourceStatus.success => RefreshIndicator(
                  color: AppColors.ink,
                  onRefresh: _reload,
                  child: _Summary(data: current.data!, money: _money),
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
  const _Summary({required this.data, required this.money});

  final ReportData data;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final remaining = summary.remainingBudget;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.hero),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo periode ini',
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: AppColors.paper.withValues(alpha: 0.7),
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                money(summary.balance),
                style: AppText.mono(
                  size: 26,
                  weight: FontWeight.w500,
                  color: AppColors.paper,
                  letterSpacing: -0.01 * 26,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCard(
                icon: LucideIcons.arrowDown,
                label: 'Pemasukan',
                value: money(summary.income),
                background: AppColors.earnSoft,
                foreground: AppColors.earn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: LucideIcons.arrowUp,
                label: 'Pengeluaran',
                value: money(summary.expense),
                background: AppColors.spendSoft,
                foreground: AppColors.spend,
              ),
            ),
          ],
        ),
        if (remaining != null) ...[
          const SizedBox(height: 12),
          _StatCard(
            icon: LucideIcons.chartPie,
            label: 'Sisa anggaran',
            value: money(remaining),
            background: remaining < 0
                ? AppColors.spendSoft
                : AppColors.earnSoft,
            foreground: remaining < 0 ? AppColors.spend : AppColors.earn,
          ),
        ],
        const SizedBox(height: 14),
        _ChangeInsight(change: data.expenseChange),
        if (data.dailyAverage > 0 ||
            data.highestSpendingDay != null ||
            data.topMerchant != null) ...[
          const SizedBox(height: 14),
          _SpendingStats(data: data, money: money),
        ],
        if (data.expensesByCategory.isNotEmpty) ...[
          const SizedBox(height: 14),
          _CategoryBreakdown(
            items: data.expensesByCategory,
            total: summary.expense,
            money: money,
          ),
        ],
      ],
    );
  }
}

class _ChangeInsight extends StatelessWidget {
  const _ChangeInsight({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final unchanged = change.abs() < 0.005;
    final decreased = change < 0;
    final percent = (change.abs() * 100).round();
    final background = unchanged || decreased
        ? AppColors.earnSoft
        : AppColors.spendSoft;
    final foreground = unchanged || decreased
        ? AppColors.earn
        : AppColors.spend;
    final icon = unchanged
        ? LucideIcons.minus
        : decreased
        ? LucideIcons.trendingDown
        : LucideIcons.trendingUp;
    final message = unchanged
        ? 'Pengeluaran sama dengan periode sebelumnya.'
        : decreased
        ? 'Pengeluaran turun $percent% dari periode sebelumnya.'
        : 'Pengeluaran naik $percent% dari periode sebelumnya.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppText.body(
                size: 13,
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

class _SpendingStats extends StatelessWidget {
  const _SpendingStats({required this.data, required this.money});

  final ReportData data;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik belanja',
          style: AppText.body(size: 13, weight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        if (data.dailyAverage > 0)
          _StatRow(
            icon: LucideIcons.calculator,
            label: 'Rata-rata harian',
            value: '${money(data.dailyAverage.round())} / hari',
          ),
        if (data.highestSpendingDay != null) ...[
          if (data.dailyAverage > 0) const SizedBox(height: 12),
          _StatRow(
            icon: LucideIcons.calendarX,
            label: 'Hari belanja terbesar',
            value:
                '${_dayLabel(data.highestSpendingDay!)} · ${money(data.highestSpendingDayAmount)}',
          ),
        ],
        if (data.topMerchant != null) ...[
          const SizedBox(height: 12),
          _StatRow(
            icon: LucideIcons.store,
            label: 'Merchant teratas',
            value: '${data.topMerchant} · ${data.topMerchantCount}x',
          ),
        ],
      ],
    ),
  );

  String _dayLabel(DateTime value) =>
      '${value.day} ${_months[value.month - 1]} ${value.year}';
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
  Widget build(BuildContext context) => AppCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rincian pengeluaran',
          style: AppText.body(size: 13, weight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
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
          '${(share * 100).round()}% dari pengeluaran',
          style: AppText.body(size: 10.5, color: AppColors.mut),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.smallButton),
          ),
          child: Icon(icon, size: 18, color: foreground),
        ),
        const SizedBox(height: 12),
        Text(label, style: AppText.body(size: 10.5, color: AppColors.mut)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppText.mono(
            size: 14,
            weight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
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
