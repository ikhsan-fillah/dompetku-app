import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_bar_icon_button.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../controllers/recurring_controller.dart';
import '../models/recurring_rule.dart';
import '../services/recurring_totals.dart';
import 'recurring_add_sheet.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/card_actions.dart';

/// Daftar recurring: item aktif/nonaktif lewat sakelar. Nonaktif tidak dihapus.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecurringController>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(
              // "Recurring transactions" terlalu panjang untuk satu baris.
              title: AppLanguage.isEnglish
                  ? 'Recurring'
                  : 'Transaksi berulang'.tr,
              action: AppBarIconButton(
                tooltip: 'Tambah transaksi berulang'.tr,
                icon: LucideIcons.plus,
                onPressed: () async {
                  final saved = await showRecurringAddSheet(context);
                  if (saved) await controller.load();
                },
              ),
            ),
            Expanded(
              child: Obx(() {
                final state = controller.state.value;
                switch (state.status) {
                  case ResourceStatus.idle:
                  case ResourceStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ResourceStatus.error:
                    return Center(
                      child: Text(
                        state.message ?? 'Gagal memuat transaksi berulang.'.tr,
                        style: AppText.body(color: AppColors.spend),
                      ),
                    );
                  case ResourceStatus.empty:
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Belum ada transaksi berulang. Tambahkan sewa, langganan, atau tagihan.'
                              .tr,
                          textAlign: TextAlign.center,
                          style: AppText.body(size: 13, color: AppColors.mut),
                        ),
                      ),
                    );
                  case ResourceStatus.success:
                    final rules = state.data ?? const <RecurringRule>[];
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      children: [
                        _TotalsRow(rules: rules),
                        const SizedBox(height: 12),
                        for (final rule in rules)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DismissibleRule(
                              rule: rule,
                              controller: controller,
                              expanded: controller.expandedId.value == rule.id,
                            ),
                          ),
                      ],
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.rules});

  final List<RecurringRule> rules;

  @override
  Widget build(BuildContext context) {
    final totals = RecurringTotals.monthly(rules);
    return Row(
      children: [
        Expanded(
          child: _TotalCard(
            label: 'Keluar per bulan'.tr,
            value: totals.out,
            color: AppColors.spend,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TotalCard(
            label: 'Masuk per bulan'.tr,
            value: totals.income,
            color: AppColors.earn,
          ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(size: 12, color: AppColors.mut)),
          const SizedBox(height: 6),
          Text(
            formatIdr(value),
            style: AppText.mono(
              size: 15,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) => showAppConfirm(
  context,
  title: 'Hapus transaksi berulang?'.tr,
  message: 'Transaksi sebelumnya tetap ada. Hanya jadwalnya yang dihapus.'.tr,
  confirmLabel: 'Hapus'.tr,
  danger: true,
);

/// Kartu aturan: geser ke kiri untuk hapus, atau ketuk untuk memunculkan
/// tombol Edit dan Hapus seperti kartu transaksi.
class _DismissibleRule extends StatelessWidget {
  const _DismissibleRule({
    required this.rule,
    required this.controller,
    required this.expanded,
  });

  final RecurringRule rule;
  final RecurringController controller;
  final bool expanded;

  Future<void> _edit(BuildContext context) async {
    final saved = await showRecurringAddSheet(context, edit: rule);
    if (saved) await controller.load();
  }

  Future<void> _delete(BuildContext context) async {
    if (await _confirmDelete(context)) await controller.remove(rule.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(rule.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => controller.remove(rule.id!),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.spendSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: AppColors.spend),
      ),
      child: _RuleTile(
        rule: rule,
        expanded: expanded,
        onTap: () => controller.toggleExpanded(rule.id),
        onToggle: (value) => controller.setActive(rule.id!, value),
        actions: [
          CardAction(
            label: 'Edit'.tr,
            icon: LucideIcons.pencil,
            onTap: () => _edit(context),
          ),
          CardAction(
            label: 'Hapus'.tr,
            icon: LucideIcons.trash2,
            danger: true,
            onTap: () => _delete(context),
          ),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.expanded,
    required this.onTap,
    required this.onToggle,
    required this.actions,
  });

  final RecurringRule rule;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final List<CardAction> actions;

  bool get _isIncome => rule.type == RecurringType.income;

  static const _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Jadwal berulang, bukan batas waktu: "tiap tanggal 5", "tiap Senin".
  String get _schedule => switch (rule.frequency) {
    RecurringFrequency.monthly => 'Bulanan · tiap tanggal @day'.trParams({
      'day': _dayLabel(rule.dayOfMonth ?? rule.startDate.day),
    }),
    RecurringFrequency.weekly => 'Mingguan · tiap @weekday'.trParams({
      'weekday': _weekdays[(rule.weekday ?? rule.startDate.weekday) - 1].tr,
    }),
    RecurringFrequency.yearly => 'Tahunan · tiap @date'.trParams({
      'date':
          '${rule.startDate.day} ${AppLanguage.monthShort(rule.startDate.month)}',
    }),
  };

  /// Bahasa Inggris memakai akhiran urutan (5th); Indonesia cukup angka.
  static String _dayLabel(int day) =>
      AppLanguage.isEnglish ? _ordinal(day) : '$day';

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }

  @override
  Widget build(BuildContext context) {
    final amountText = _isIncome
        ? '+ ${formatIdr(rule.amount)}'
        : '- ${formatIdr(rule.amount)}';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isIncome ? AppColors.earn : AppColors.catBills,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isIncome ? LucideIcons.wallet : LucideIcons.receiptText,
                      size: 18,
                      color: AppColors.card,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.name,
                          style: AppText.body(
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$amountText · $_schedule',
                          style: AppText.mono(size: 11, color: AppColors.mut),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rule.isActive,
                    activeTrackColor: AppColors.ink,
                    onChanged: onToggle,
                  ),
                ],
              ),
            ),
          ),
          CardActionBar(
            expanded: expanded,
            padding: const EdgeInsets.fromLTRB(66, 0, 14, 12),
            actions: actions,
          ),
        ],
      ),
    );
  }
}
