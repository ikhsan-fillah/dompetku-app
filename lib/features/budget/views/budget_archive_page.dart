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
import '../widgets/confirm_delete_budget.dart';
import '../../../core/widgets/app_dialog.dart';

/// Layar daftar anggaran terarsip dengan opsi pulihkan.
class BudgetArchivePage extends StatefulWidget {
  const BudgetArchivePage({super.key});

  @override
  State<BudgetArchivePage> createState() => _BudgetArchivePageState();
}

class _BudgetArchivePageState extends State<BudgetArchivePage> {
  final controller = Get.find<BudgetController>();

  @override
  void initState() {
    super.initState();
    // Tanpa ini daftar tidak pernah dimuat dan layar berputar terus.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.loadArchived(),
    );
  }

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
    final confirmed = await showAppConfirm(
      context,
      title: 'Pulihkan anggaran?'.tr,
      message:
          '"@name" akan kembali muncul di daftar anggaran aktif. Histori transaksi tidak berubah.'
              .trParams({'name': item.budget.name}),
      confirmLabel: 'Pulihkan'.tr,
    );
    if (!confirmed) return;
    await controller.restore(item.budget.id!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    body: SafeArea(
      child: Column(
        children: [
          AppTitleBar(title: 'Anggaran terarsip'.tr),
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
                        current.message ?? 'Gagal memuat anggaran terarsip.'.tr,
                        style: AppText.body(color: AppColors.ink2),
                      ),
                      TextButton(
                        onPressed: controller.loadArchived,
                        child: Text('Coba lagi'.tr),
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
                        'Tidak ada anggaran terarsip'.tr,
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
                      onDelete: () => confirmDeleteBudget(
                        context,
                        controller,
                        current.data![index],
                      ),
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
    required this.onDelete,
  });

  final BudgetViewModel item;
  final String Function(int) money;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

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
                      ? '@used dari @limit · keseluruhan'.trParams({
                          'used': money(item.used),
                          'limit': money(item.budget.amountLimit),
                        })
                      : '@used dari @limit'.trParams({
                          'used': money(item.used),
                          'limit': money(item.budget.amountLimit),
                        }),
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
            label: Text('Pulihkan'.tr),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          ),
          IconButton(
            tooltip: 'Hapus'.tr,
            onPressed: onDelete,
            icon: const Icon(
              LucideIcons.trash2,
              size: 18,
              color: AppColors.spend,
            ),
          ),
        ],
      ),
    );
  }
}
