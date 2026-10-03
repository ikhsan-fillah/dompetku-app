import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/widgets/app_back_button.dart';
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
    backgroundColor: const Color(0xFFF6FAF9),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Laporan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
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
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => _selectPreset(preset),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFFCCFBF1),
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFE2E8F0),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF64748B),
                  ),
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
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                  child: CircularProgressIndicator(),
                ),
                ResourceStatus.empty => _Message(
                  icon: Icons.insert_chart_outlined_rounded,
                  text: 'Belum ada transaksi pada periode ini',
                  action: 'Muat ulang',
                  onTap: _reload,
                ),
                ResourceStatus.error => _Message(
                  icon: Icons.error_outline_rounded,
                  text: current.message ?? 'Gagal memuat laporan.',
                  action: 'Coba lagi',
                  onTap: _reload,
                ),
                ResourceStatus.success => RefreshIndicator(
                  color: const Color(0xFF0F766E),
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

const _cardShadow = [
  BoxShadow(color: Color(0x170F766E), blurRadius: 22, offset: Offset(0, 6)),
];

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF0F766E), Color(0xFF10B981)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: _cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo periode ini',
                style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                money(summary.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
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
                icon: Icons.arrow_downward_rounded,
                label: 'Pemasukan',
                value: money(summary.income),
                background: const Color(0xFFCCFBF1),
                foreground: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.arrow_upward_rounded,
                label: 'Pengeluaran',
                value: money(summary.expense),
                background: const Color(0xFFFFE4E9),
                foreground: const Color(0xFFF43F5E),
              ),
            ),
          ],
        ),
        if (remaining != null) ...[
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Sisa anggaran',
            value: money(remaining),
            background: remaining < 0
                ? const Color(0xFFFFE4E9)
                : const Color(0xFFCCFBF1),
            foreground: remaining < 0
                ? const Color(0xFFF43F5E)
                : const Color(0xFF0F766E),
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
    final background = unchanged
        ? const Color(0xFFCCFBF1)
        : decreased
        ? const Color(0xFFCCFBF1)
        : const Color(0xFFFFE4E9);
    final foreground = unchanged
        ? const Color(0xFF0F766E)
        : decreased
        ? const Color(0xFF0F766E)
        : const Color(0xFFF43F5E);
    final icon = unchanged
        ? Icons.trending_flat_rounded
        : decreased
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;
    final message = unchanged
        ? 'Pengeluaran sama dengan periode sebelumnya.'
        : decreased
        ? 'Pengeluaran turun $percent% dari periode sebelumnya.'
        : 'Pengeluaran naik $percent% dari periode sebelumnya.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: _cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik belanja',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        if (data.dailyAverage > 0)
          _StatRow(
            icon: Icons.calculate_outlined,
            label: 'Rata-rata harian',
            value: '${money(data.dailyAverage.round())} / hari',
          ),
        if (data.highestSpendingDay != null) ...[
          if (data.dailyAverage > 0) const SizedBox(height: 12),
          _StatRow(
            icon: Icons.event_busy_rounded,
            label: 'Hari belanja terbesar',
            value:
                '${_dayLabel(data.highestSpendingDay!)} · ${money(data.highestSpendingDayAmount)}',
          ),
        ],
        if (data.topMerchant != null) ...[
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.storefront_outlined,
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
        decoration: const BoxDecoration(
          color: Color(0xFFCCFBF1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: _cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rincian pengeluaran',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              money(item.amount),
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFFEEF2F5)),
                ),
                FractionallySizedBox(
                  widthFactor: share.clamp(0.0, 1.0),
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${(share * 100).round()}% dari pengeluaran',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: _cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: foreground),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
        Icon(icon, size: 56, color: const Color(0xFF0F766E)),
        const SizedBox(height: 12),
        Text(text),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}
