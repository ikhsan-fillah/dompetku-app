import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_view_model.dart';

/// Layar daftar anggaran terarsip dengan opsi pulihkan.
class BudgetArchivePage extends GetView<BudgetController> {
  const BudgetArchivePage({super.key});

  String _money(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp$buffer';
  }

  Future<void> _confirmRestore(BudgetViewModel item) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Pulihkan anggaran?'),
        content: Text(
          '"${item.budget.name}" akan kembali muncul di daftar anggaran aktif. '
          'Histori transaksi tidak berubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.restore(item.budget.id!);
    if (ok) Get.rawSnackbar(message: 'Anggaran dipulihkan.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF6FAF9),
        appBar: AppBar(
          title: const Text('Anggaran terarsip'),
          backgroundColor: const Color(0xFFF6FAF9),
          surfaceTintColor: Colors.transparent,
        ),
        body: Obx(() {
          final current = controller.archived.value;
          return switch (current.status) {
            ResourceStatus.idle ||
            ResourceStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            ResourceStatus.error => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(current.message ?? 'Gagal memuat anggaran terarsip.'),
                    TextButton(
                      onPressed: controller.loadArchived,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ResourceStatus.empty => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: AppColors.teal,
                    ),
                    SizedBox(height: 12),
                    Text('Tidak ada anggaran terarsip'),
                  ],
                ),
              ),
            ResourceStatus.success => RefreshIndicator(
                color: AppColors.teal,
                onRefresh: controller.loadArchived,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: current.data!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, index) => _ArchivedCard(
                        item: current.data![index],
                        money: _money,
                        onRestore: () => _confirmRestore(current.data![index]),
                      ),
                ),
              ),
          };
        }),
      );
}

class _ArchivedCard extends StatelessWidget {
  const _ArchivedCard({
    required this.item,
    required this.money,
    required this.onRestore,
  });

  final BudgetViewModel item;
  final String Function(int) money;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.muted,
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
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  item.isOverall
                      ? '${money(item.used)} dari ${money(item.budget.amountLimit)} · keseluruhan'
                      : '${money(item.used)} dari ${money(item.budget.amountLimit)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: const Text('Pulihkan'),
          ),
        ],
      ),
    );
  }
}
