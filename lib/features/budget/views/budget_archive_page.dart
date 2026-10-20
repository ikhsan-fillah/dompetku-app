import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_icon_box.dart';
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          side: const BorderSide(color: AppColors.line),
        ),
        title: Text('Pulihkan anggaran?', style: AppText.display(size: 20)),
        content: Text(
          '"${item.budget.name}" akan kembali muncul di daftar anggaran aktif. '
          'Histori transaksi tidak berubah.',
          style: AppText.body(size: 13, color: AppColors.ink2),
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
    await controller.restore(item.budget.id!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    body: SafeArea(
      child: Column(
        children: [
          const AppTitleBar(title: 'Anggaran terarsip'),
          Expanded(
            child: Obx(() {
              final current = controller.archived.value;
              return switch (current.status) {
                ResourceStatus.idle || ResourceStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                ResourceStatus.error => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        current.message ?? 'Gagal memuat anggaran terarsip.',
                        style: AppText.body(color: AppColors.ink2),
                      ),
                      TextButton(
                        onPressed: controller.loadArchived,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
                ResourceStatus.empty => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.paper2,
                          borderRadius: BorderRadius.circular(
                            AppRadius.hero - 2,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.archive,
                          size: 28,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada anggaran terarsip',
                        style: AppText.body(size: 14, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                ResourceStatus.success => RefreshIndicator(
                  color: AppColors.ink,
                  onRefresh: controller.loadArchived,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: current.data!.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.gap),
                    itemBuilder: (_, index) => _ArchivedCard(
                      item: current.data![index],
                      money: _money,
                      onRestore: () => _confirmRestore(current.data![index]),
                    ),
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
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          CategoryIconBox(
            icon: LucideIcons.package,
            color: AppColors.mut,
            size: 40,
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
                  style: AppText.body(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  item.isOverall
                      ? '${money(item.used)} dari ${money(item.budget.amountLimit)} · keseluruhan'
                      : '${money(item.used)} dari ${money(item.budget.amountLimit)}',
                  style: AppText.mono(
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppColors.mut,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(LucideIcons.undo2, size: 16),
            label: const Text('Pulihkan'),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
