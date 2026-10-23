import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/budget_status.dart';
import '../../../core/widgets/app_bar_icon_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/budget_level_style.dart';
import '../../../core/widgets/sort_chip.dart';
import '../../transaction/widgets/transaction_form_sheet.dart';
import '../../../core/i18n/app_language.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_view_model.dart';
import '../services/budget_list_service.dart';
import '../widgets/confirm_delete_budget.dart';
import '../../../core/widgets/app_dialog.dart';

class BudgetPage extends GetView<BudgetController> {
  const BudgetPage({super.key});

  String _money(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp$buffer';
  }

  Future<void> _openForm([BudgetViewModel? item]) async {
    await showTransactionSheet(
      Get.context!,
      editBudget: item?.budget,
      initialMode: FinancialInputMode.budget,
    );
    await controller.load(silent: true);
  }

  Future<void> _confirmArchive(
    BuildContext context,
    BudgetViewModel item,
  ) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Arsipkan anggaran?'.tr,
      message:
          '"@name" dipindahkan ke arsip. Riwayat transaksi tidak ikut terhapus.'
              .trParams({'name': item.budget.name}),
      confirmLabel: 'Arsipkan'.tr,
    );
    if (confirmed) {
      await controller.archive(item.budget.id!);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          controller: controller,
          onArchive: () => Get.toNamed(AppRoutes.budgetArchive),
        ),
        Expanded(
          child: Obx(() {
            final current = controller.state.value;
            return switch (current.status) {
              ResourceStatus.idle || ResourceStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ResourceStatus.empty => _Empty(onCreate: _openForm),
              ResourceStatus.error => _Error(
                message: current.message ?? 'Gagal memuat anggaran.'.tr,
                onRetry: controller.load,
              ),
              ResourceStatus.success => RefreshIndicator(
                color: AppColors.ink,
                onRefresh: controller.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    4,
                    AppSpacing.page,
                    160,
                  ),
                  children: _sections(context),
                ),
              ),
            };
          }),
        ),
      ],
    ),
  );

  Future<void> _showActions(BuildContext context, BudgetViewModel item) {
    final title = item.labelsFor(_categoryName(item)).title;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: AppText.display(size: 20)),
            ),
            ListTile(
              leading: const Icon(LucideIcons.pencil, size: 18),
              title: Text('Edit'.tr, style: AppText.body(size: 14)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openForm(item);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.archive, size: 18),
              title: Text('Arsipkan'.tr, style: AppText.body(size: 14)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmArchive(context, item);
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.trash2,
                size: 18,
                color: AppColors.spend,
              ),
              title: Text(
                'Hapus'.tr,
                style: AppText.body(size: 14, color: AppColors.spend),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                confirmDeleteBudget(context, controller, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _categoryName(BudgetViewModel item) => item.isOverall
      ? 'Total'.tr
      : controller.categoryNames[item.budget.categoryId];

  List<Widget> _sections(BuildContext context) {
    final items = controller.visibleItems;
    final totals = _totals(items);
    final level = BudgetStatus.levelFor(
      BudgetStatus.percentUsed(used: totals.used, limit: totals.limit),
    );
    final banner = _thresholdBanner(level);
    return [
      _SummaryHero(limit: totals.limit, used: totals.used, money: _money),
      if (banner != null) ...[const SizedBox(height: 14), banner],
      const SizedBox(height: 14),
      AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per kategori'.tr,
              style: AppText.body(size: 13, weight: FontWeight.w700),
            ),
            for (var i = 0; i < items.length; i++)
              _BudgetRow(
                item: items[i],
                money: _money,
                categoryName: _categoryName(items[i]),
                last: i == items.length - 1,
                onTap: () => _showActions(context, items[i]),
              ),
          ],
        ),
      ),
    ];
  }
}

({int limit, int used}) _totals(List<BudgetViewModel> items) {
  final scoped = items.where((item) => !item.isOverall).toList();
  final basis = scoped.isEmpty ? items : scoped;
  final limit = basis.fold<int>(
    0,
    (sum, item) => sum + item.budget.amountLimit,
  );
  final used = basis.fold<int>(0, (sum, item) => sum + item.used);
  return (limit: limit, used: used);
}

Widget? _thresholdBanner(BudgetLevel level) => switch (level) {
  BudgetLevel.safe => null,
  BudgetLevel.warning => _ThresholdBanner(
    level: BudgetLevel.warning,
    title: 'Sudah 75% terpakai'.tr,
    subtitle: 'Masih ada waktu untuk mengatur ritme'.tr,
  ),
  BudgetLevel.critical => _ThresholdBanner(
    level: BudgetLevel.critical,
    title: 'Hampir habis (90%)'.tr,
    subtitle: 'Kurangi pengeluaran non-esensial'.tr,
  ),
  BudgetLevel.exceeded => _ThresholdBanner(
    level: BudgetLevel.exceeded,
    title: 'Batas terlewati'.tr,
    subtitle: 'Pengeluaran melewati batas bulan ini'.tr,
  ),
};

/// Judul halaman di dalam body (sama seperti tab Profil dan Transaksi).
class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onArchive});

  final BudgetController controller;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return AppPageHeader(
      title: 'Anggaran'.tr,
      actions: [
        Obx(
          () => SortChip<BudgetSort>(
            value: controller.sort.value,
            options: BudgetSort.values,
            chipLabel: _sortChipLabel,
            menuLabel: _sortLabel,
            onSelected: controller.setSort,
            tooltip: 'Urutkan anggaran'.tr,
          ),
        ),
        const SizedBox(width: 4),
        AppBarIconButton(
          tooltip: 'Anggaran terarsip'.tr,
          icon: LucideIcons.archive,
          onPressed: onArchive,
        ),
      ],
    );
  }
}

String _sortLabel(BudgetSort sort) => switch (sort) {
  BudgetSort.persentaseTerpakaiTertinggi => 'Terpakai tertinggi'.tr,
  BudgetSort.sisaTerkecil => 'Sisa terkecil'.tr,
  BudgetSort.limitTerbesar => 'Limit terbesar'.tr,
  BudgetSort.namaAZ => 'Nama A-Z'.tr,
  BudgetSort.namaZA => 'Nama Z-A'.tr,
};

String _sortChipLabel(BudgetSort sort) => switch (sort) {
  BudgetSort.persentaseTerpakaiTertinggi => 'Terpakai'.tr,
  BudgetSort.sisaTerkecil => 'Sisa'.tr,
  BudgetSort.limitTerbesar => 'Limit'.tr,
  BudgetSort.namaAZ => 'A-Z'.tr,
  BudgetSort.namaZA => 'Z-A'.tr,
};

/// Blok tinta ringkasan anggaran (spec §3.5 varian Anggaran).
class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.limit,
    required this.used,
    required this.money,
  });

  final int limit;
  final int used;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final remaining = limit - used;
    final percent = BudgetStatus.percentUsed(used: used, limit: limit);
    final level = BudgetStatus.levelFor(percent);
    final muted = AppColors.paper.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BATAS @month'.trParams({
              'month': AppLanguage.monthLong(
                DateTime.now().month,
              ).toUpperCase(),
            }),
            style: AppText.label(color: muted, size: 11.5),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: money(used),
                    style: AppText.display(
                      size: 30,
                      color: AppColors.paper,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${money(limit)}',
                    style: AppText.mono(
                      size: 12,
                      weight: FontWeight.w400,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppProgressBar(
            value: (percent / 100).clamp(0.0, 1.0).toDouble(),
            color: level.solid,
            height: 8,
            trackColor: AppColors.paper.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining < 0
                      ? 'Melebihi @amount'.trParams({
                          'amount': money(-remaining),
                        })
                      : 'Sisa @amount'.trParams({'amount': money(remaining)}),
                  style: AppText.mono(size: 12.5, color: AppColors.paper),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  level.label,
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w700,
                    color: level.foreground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThresholdBanner extends StatelessWidget {
  const _ThresholdBanner({
    required this.level,
    required this.title,
    required this.subtitle,
  });

  final BudgetLevel level;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: level.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.triangleAlert, size: 18, color: level.foreground),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: level.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.body(size: 10.5, color: AppColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

String _plain(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Baris anggaran di dalam kartu "Per kategori".tr: satu judul, persen di
/// kanan, lalu periode dan status, bar, dan pemakaian. Ketuk untuk Edit atau
/// Arsipkan.
class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.item,
    required this.money,
    required this.categoryName,
    required this.last,
    required this.onTap,
  });

  final BudgetViewModel item;
  final String Function(int) money;
  final String? categoryName;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = item.level;
    final percentText = item.percent.toStringAsFixed(0);
    final status = switch (item.level) {
      BudgetLevel.safe => 'Sisa @amount'.trParams({
        'amount': money(item.remaining),
      }),
      BudgetLevel.warning => 'Mendekati batas • Sisa @amount'.trParams({
        'amount': money(item.remaining),
      }),
      BudgetLevel.critical => 'Hampir habis • Sisa @amount'.trParams({
        'amount': money(item.remaining),
      }),
      BudgetLevel.exceeded => 'Melebihi batas @amount'.trParams({
        'amount': money(-item.remaining),
      }),
    };
    final labels = item.labelsFor(categoryName);
    final period =
        '${_date(item.budget.startDate)} – ${_date(item.budget.endDate)}';
    final subtitle = [
      if (labels.category != null) labels.category!,
      period,
      status,
    ].join(' · ');
    final note = item.budget.note?.trim();

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: last
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line2)),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    labels.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 13.5, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percentText%',
                  style: AppText.mono(size: 12, color: level.foreground),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppText.body(size: 10.5, color: AppColors.mut),
            ),
            const SizedBox(height: 8),
            AppProgressBar(
              value: (item.percent / 100).clamp(0.0, 1.0).toDouble(),
              color: level.solid,
              height: 6,
            ),
            const SizedBox(height: 6),
            Text(
              '@used dari @limit'.trParams({
                'used': _plain(item.used),
                'limit': _plain(item.budget.amountLimit),
              }),
              style: AppText.mono(
                size: 11,
                weight: FontWeight.w400,
                color: AppColors.mut,
              ),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 11, color: AppColors.mut),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(AppRadius.hero - 2),
            ),
            child: const Icon(
              LucideIcons.wallet,
              size: 28,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada anggaran'.tr,
            style: AppText.body(size: 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Atur batas pengeluaran bulanan agar keuangan lebih terkendali.'.tr,
            textAlign: TextAlign.center,
            style: AppText.body(size: 13, color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          AppButton(
            expand: false,
            kind: AppButtonKind.primary,
            onPressed: onCreate,
            icon: LucideIcons.plus,
            label: 'Buat anggaran'.tr,
          ),
        ],
      ),
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function({bool silent}) onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: AppText.body(color: AppColors.ink2)),
        TextButton(onPressed: onRetry, child: Text('Coba lagi'.tr)),
      ],
    ),
  );
}
