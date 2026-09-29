import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/budget_status.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_view_model.dart';

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
    await Get.toNamed(AppRoutes.budgetForm, arguments: item?.budget);
    await controller.load(silent: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF6FAF9),
        appBar: AppBar(
          title: const Text('Anggaran'),
          backgroundColor: const Color(0xFFF6FAF9),
          surfaceTintColor: Colors.transparent,
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 84),
          child: FloatingActionButton.extended(
            onPressed: _openForm,
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          ),
        ),
        body: Obx(() {
          final current = controller.state.value;
          return switch (current.status) {
            ResourceStatus.idle || ResourceStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            ResourceStatus.empty => _Empty(onReload: controller.load),
            ResourceStatus.error => _Error(
                message: current.message ?? 'Gagal memuat anggaran.',
                onRetry: controller.load,
              ),
            ResourceStatus.success => RefreshIndicator(
                color: const Color(0xFF0F766E),
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: current.data!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, index) {
                    final item = current.data![index];
                    return _BudgetCard(
                      item: item,
                      money: _money,
                      onEdit: () => _openForm(item),
                      onArchive: () => controller.archive(item.budget.id!),
                    );
                  },
                ),
              ),
          };
        }),
      );
}

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.budget.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                  ),
                  const SizedBox(height: 7),
                  _StatusChip(visual: visual),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              color: Colors.white,
              onSelected: (value) => value == 'edit' ? onEdit() : onArchive(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 9,
              child: Stack(children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFFEEF2F5)),
                ),
                FractionallySizedBox(
                  widthFactor: (item.percent / 100).clamp(0.0, 1.0).toDouble(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: visual.gradient),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
              child: Text(
                '${money(item.used)} dari ${money(item.budget.amountLimit)}',
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percentText%',
              style: TextStyle(
                color: visual.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 5),
          Text(
            status,
            style: TextStyle(
              color: visual.foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
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
            gradient: LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
            ),
          ),
        BudgetLevel.warning => const _BudgetVisual(
            label: 'Waspada 75%',
            background: Color(0xFFFEF3C7),
            foreground: Color(0xFFB45309),
            gradient: LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            ),
          ),
        BudgetLevel.critical => const _BudgetVisual(
            label: 'Kritis 90%',
            background: Color(0xFFFFEDD5),
            foreground: Color(0xFFC2410C),
            gradient: LinearGradient(
              colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
            ),
          ),
        BudgetLevel.exceeded => const _BudgetVisual(
            label: 'Habis 100%',
            background: Color(0xFFFFE4E9),
            foreground: Color(0xFFF43F5E),
            gradient: LinearGradient(
              colors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
            ),
          ),
      };
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onReload});
  final Future<void> Function({bool silent}) onReload;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: Color(0xFF0F766E),
          ),
          const SizedBox(height: 12),
          const Text('Belum ada anggaran'),
          TextButton(onPressed: onReload, child: const Text('Muat ulang')),
        ]),
      );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function({bool silent}) onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ]),
      );
}
