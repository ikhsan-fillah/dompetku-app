import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_view_model.dart';

/// Menanyakan konfirmasi, lalu menghapus anggaran permanen bila disetujui.
/// Dipakai daftar aktif dan daftar arsip.
Future<void> confirmDeleteBudget(
  BuildContext context,
  BudgetController controller,
  BudgetViewModel item,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        side: const BorderSide(color: AppColors.line),
      ),
      title: Text('Hapus anggaran?'.tr, style: AppText.display(size: 20)),
      content: Text(
        '"@name" dihapus permanen dan tidak bisa dipulihkan. Riwayat transaksi tidak ikut terhapus.'
            .trParams({'name': item.budget.name}),
        style: AppText.body(size: 13, color: AppColors.ink2),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Batal'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.spend),
          child: Text('Hapus'.tr),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.delete(item.budget.id!);
  }
}
