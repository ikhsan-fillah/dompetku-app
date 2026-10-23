import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_dialog.dart';
import '../controllers/budget_controller.dart';
import '../models/budget_view_model.dart';

/// Menanyakan konfirmasi, lalu menghapus anggaran permanen bila disetujui.
/// Dipakai daftar aktif dan daftar arsip.
Future<void> confirmDeleteBudget(
  BuildContext context,
  BudgetController controller,
  BudgetViewModel item,
) async {
  final confirmed = await showAppConfirm(
    context,
    title: 'Hapus anggaran?'.tr,
    message:
        '"@name" dihapus permanen dan tidak bisa dipulihkan. Riwayat transaksi tidak ikut terhapus.'
            .trParams({'name': item.budget.name}),
    confirmLabel: 'Hapus'.tr,
    danger: true,
  );
  if (confirmed) {
    await controller.delete(item.budget.id!);
  }
}
