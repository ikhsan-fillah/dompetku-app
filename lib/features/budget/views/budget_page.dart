import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/budget_status.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../transaction/widgets/transaction_form_sheet.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_view_model.dart';
import '../services/budget_list_service.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arsipkan anggaran?'),
        content: Text(
          '"${item.budget.name}" dipindahkan ke arsip. Riwayat transaksi tidak ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
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
                message: current.message ?? 'Gagal memuat anggaran.',
                onRetry: controller.load,
              ),
              ResourceStatus.success => RefreshIndicator(
                color: AppColors.teal,
                onRefresh: controller.load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    4,
                    AppSpacing.page,
                    160,
                  ),
                  itemCount: controller.visibleItems.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (itemContext, index) {
                    if (index == 0) {
                      return _SummaryHero(
                        items: controller.visibleItems,
                        money: _money,
                      );
                    }
                    final item = controller.visibleItems[index - 1];
                    return _BudgetCard(
                      item: item,
                      money: _money,
                      onEdit: () => _openForm(item),
                      onArchive: () => _confirmArchive(itemContext, item),
                    );
                  },
                ),
              ),
            };
          }),
        ),
      ],
    ),
  );
}

/// Judul halaman di dalam body (sama seperti tab Profil dan Transaksi).
class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.onArchive});

  final BudgetController controller;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Anggaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Obx(() {
            final selected = controller.sort.value;
            return PopupMenuButton<BudgetSort>(
              tooltip: 'Urutkan anggaran',
              icon: const Icon(Icons.sort_rounded),
              onSelected: controller.setSort,
              itemBuilder: (_) => [
                for (final sort in BudgetSort.values)
                  CheckedPopupMenuItem(
                    value: sort,
                    checked: selected == sort,
                    child: Text(_sortLabel(sort)),
                  ),
              ],
            );
          }),
          Tooltip(
            message: 'Anggaran terarsip',
            child: Material(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onArchive,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sortLabel(BudgetSort sort) => switch (sort) {
  BudgetSort.persentaseTerpakaiTertinggi => 'Terpakai tertinggi',
  BudgetSort.sisaTerkecil => 'Sisa terkecil',
  BudgetSort.limitTerbesar => 'Limit terbesar',
  BudgetSort.namaAZ => 'Nama A-Z',
};

/// Kartu ringkasan bergradasi (gaya sama dengan kartu saldo di Beranda).
class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.items, required this.money});

  final List<BudgetViewModel> items;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final scoped = items.where((item) => !item.isOverall).toList();
    final basis = scoped.isEmpty ? items : scoped;
    final limit = basis.fold<int>(
      0,
      (sum, item) => sum + item.budget.amountLimit,
    );
    final used = basis.fold<int>(0, (sum, item) => sum + item.used);
    final remaining = limit - used;
    final ratio = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0).toDouble();
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      gradient: AppColors.heroGradient,
      radius: AppRadius.hero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total anggaran aktif',
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(limit),
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStat(label: 'Terpakai', value: money(used)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: remaining < 0 ? 'Melebihi' : 'Sisa',
                  value: money(remaining < 0 ? -remaining : remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.item,
    required this.money,
    required this.onEdit,
    required this.onArchive,
  });

  final BudgetViewModel item;
  final String Function(int) money;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final visual = _BudgetVisual.forLevel(item.level);
    final percentText = item.percent.toStringAsFixed(0);
    final status = switch (item.level) {
      BudgetLevel.safe => 'Sisa ${money(item.remaining)}',
      BudgetLevel.warning => 'Mendekati batas • Sisa ${money(item.remaining)}',
      BudgetLevel.critical => 'Hampir habis • Sisa ${money(item.remaining)}',
      BudgetLevel.exceeded => 'Melebihi batas ${money(-item.remaining)}',
    };
    final period =
        '${_date(item.budget.startDate)} – ${_date(item.budget.endDate)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x170F766E),
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.isOverall
                        ? Icons.account_balance_wallet_outlined
                        : Icons.category_outlined,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.budget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.isOverall ? 'Anggaran lama' : 'Per kategori'} · $period',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: Colors.white,
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onArchive(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      money(item.used),
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$percentText%',
                  style: TextStyle(
                    color: visual.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (item.budget.note?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                item.budget.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
            Text(
              'dari ${money(item.budget.amountLimit)}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0xFFEEF2F5)),
                    ),
                    FractionallySizedBox(
                      widthFactor: (item.percent / 100)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: visual.gradient),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      color: visual.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(visual: visual),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.visual});
  final _BudgetVisual visual;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: visual.background,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      visual.label,
      style: TextStyle(
        color: visual.foreground,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _BudgetVisual {
  const _BudgetVisual({
    required this.label,
    required this.background,
    required this.foreground,
    required this.gradient,
  });

  final String label;
  final Color background;
  final Color foreground;
  final LinearGradient gradient;

  factory _BudgetVisual.forLevel(BudgetLevel level) => switch (level) {
    BudgetLevel.safe => const _BudgetVisual(
      label: 'Aman < 75%',
      background: Color(0xFFCCFBF1),
      foreground: Color(0xFF0F766E),
      gradient: LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF10B981)]),
    ),
    BudgetLevel.warning => const _BudgetVisual(
      label: 'Waspada 75%',
      background: Color(0xFFFEF3C7),
      foreground: Color(0xFFB45309),
      gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
    ),
    BudgetLevel.critical => const _BudgetVisual(
      label: 'Kritis 90%',
      background: Color(0xFFFFEDD5),
      foreground: Color(0xFFC2410C),
      gradient: LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFEA580C)]),
    ),
    BudgetLevel.exceeded => const _BudgetVisual(
      label: 'Habis 100%',
      background: Color(0xFFFFE4E9),
      foreground: Color(0xFFF43F5E),
      gradient: LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFF43F5E)]),
    ),
  };
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 36,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada anggaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Atur batas pengeluaran bulanan agar keuangan lebih terkendali.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          AppButton(
            expand: false,
            kind: AppButtonKind.primary,
            onPressed: onCreate,
            icon: Icons.add,
            label: 'Buat anggaran',
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
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}
