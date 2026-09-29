import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_view_model.dart';

class BudgetPage extends GetView<BudgetController> {
  const BudgetPage({super.key});

  String _money(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp$buffer';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Anggaran')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: current.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _BudgetCard(
                    item: current.data![index],
                    money: _money,
                  ),
                ),
              ),
          };
        }),
      );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.item, required this.money});
  final BudgetViewModel item;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final over = item.isOverBudget;
    final warning = !over && item.percent >= 80;
    final color = over
        ? Theme.of(context).colorScheme.error
        : warning
            ? Colors.orange
            : Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(item.budget.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Icon(Icons.more_vert, color: Theme.of(context).colorScheme.outline),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (item.percent.clamp(0, 100) as num) / 100,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: .15),
            ),
          ),
          const SizedBox(height: 10),
          Text('${money(item.used)} dari ${money(item.budget.amountLimit)}'),
          const SizedBox(height: 4),
          Text(
            over
                ? 'Melebihi batas ${money(item.used - item.budget.amountLimit)}'
                : 'Sisa ${money(item.remaining)} • ${item.percent.toStringAsFixed(0)}%',
            style: TextStyle(color: color),
          ),
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
