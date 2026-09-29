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
        appBar: AppBar(title: const Text('Anggaran')),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 84),
          child: FloatingActionButton.extended(
            onPressed: _openForm,
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
                onRefresh: controller.load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: current.data!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    final limit = item.budget.amountLimit;
    final level = item.level;
    final color = switch (level) {
      BudgetLevel.safe => Theme.of(context).colorScheme.primary,
      BudgetLevel.warning => const Color(0xFFD97706),
      BudgetLevel.critical => const Color(0xFFEA580C),
      BudgetLevel.exceeded => const Color(0xFFBE123C),
    };
    final percentText = item.percent.toStringAsFixed(0);
    final status = switch (level) {
      BudgetLevel.safe => 'Sisa ${money(item.remaining)} \u2022 $percentText%',
      BudgetLevel.warning =>
        'Mendekati batas \u2022 Sisa ${money(item.remaining)} \u2022 $percentText%',
      BudgetLevel.critical =>
        'Hampir habis \u2022 Sisa ${money(item.remaining)} \u2022 $percentText%',
      BudgetLevel.exceeded => 'Melebihi batas ${money(item.remaining)}',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(item.budget.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onArchive(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (item.percent / 100).clamp(0.0, 1.0).toDouble(),
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: .15),
            ),
          ),
          const SizedBox(height: 10),
          Text('${money(item.used)} dari ${money(limit)}'),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: color)),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onReload});
  final Future<void> Function({bool silent}) onReload;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 56),
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
