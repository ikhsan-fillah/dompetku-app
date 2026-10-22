import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../controllers/draft_controller.dart';
import '../models/draft_model.dart';

/// Daftar draft hasil deteksi. Confirm, Edit (lewat Confirm), atau Dismiss.
class DraftsPage extends StatelessWidget {
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DraftController>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(title: 'Draf'.tr),
            Expanded(
              child: Obx(() {
                final state = controller.state.value;
                switch (state.status) {
                  case ResourceStatus.idle:
                  case ResourceStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ResourceStatus.error:
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.message ?? 'Gagal memuat draf.'.tr,
                            style: AppText.body(color: AppColors.spend),
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Coba lagi'.tr,
                            expand: false,
                            onPressed: controller.load,
                          ),
                        ],
                      ),
                    );
                  case ResourceStatus.empty:
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Belum ada draf. Pembayaran yang terdeteksi akan muncul di sini.'
                              .tr,
                          textAlign: TextAlign.center,
                          style: AppText.body(size: 13, color: AppColors.mut),
                        ),
                      ),
                    );
                  case ResourceStatus.success:
                    final items = state.data ?? const <DraftModel>[];
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (items.length > 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: controller.confirmAll,
                              child: Text(
                                'Konfirmasi semua'.tr,
                                style: AppText.body(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        for (final draft in items) _DraftCard(draft: draft),
                        const SizedBox(height: 12),
                        Text(
                          'Teks notifikasi mentah tidak pernah disimpan.'.tr,
                          textAlign: TextAlign.center,
                          style: AppText.body(size: 11, color: AppColors.mut),
                        ),
                      ],
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});

  final DraftModel draft;

  Future<void> _confirm(
    BuildContext context,
    DraftController controller,
  ) async {
    var target = draft;
    if (draft.categoryId == null) {
      final categoryId = await _pickCategory(context, controller);
      if (categoryId == null) return;
      target = draft.copyWith(categoryId: categoryId);
    }
    final ok = await controller.confirm(target);
    if (!ok && context.mounted) {
      final message =
          controller.error.value ?? 'Gagal mengonfirmasi. Coba lagi.'.tr;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _edit(BuildContext context, DraftController controller) async {
    final amount = TextEditingController(text: draft.amount.toString());
    final name = TextEditingController(text: draft.merchant ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ubah draf'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: 'Nama'.tr),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah (IDR)'.tr,
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text('Batal'.tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text('Simpan & konfirmasi'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final value = int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final merchant = name.text;
    amount.dispose();
    name.dispose();
    if (ok != true || value == null || value <= 0) return;
    if (!context.mounted) return;
    var target = draft;
    if (draft.categoryId == null) {
      final categoryId = await _pickCategory(context, controller);
      if (categoryId == null) return;
      target = draft.copyWith(categoryId: categoryId);
    }
    final saved = await controller.editAndConfirm(
      target,
      amount: value,
      merchant: merchant,
    );
    if (!saved && context.mounted) {
      final message = controller.error.value ?? 'Gagal menyimpan perubahan.'.tr;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<int?> _pickCategory(
    BuildContext context,
    DraftController controller,
  ) async {
    final categories = await controller.expenseCategories(kind: draft.kind);
    if (!context.mounted) return null;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Pilih kategori'.tr, style: AppText.display(size: 20)),
            const SizedBox(height: 8),
            for (final category in categories)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(category.displayName),
                onTap: () => Navigator.of(sheetContext).pop(category.id),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DraftController>();
    final sign = draft.kind == TransactionType.income ? '+' : '−';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.source.tr,
            style: AppText.body(size: 11, color: AppColors.mut),
          ),
          const SizedBox(height: 4),
          Text(
            '$sign ${formatIdr(draft.amount)}',
            style: AppText.mono(size: 14, color: AppColors.ink),
          ),
          if (draft.merchant != null) ...[
            const SizedBox(height: 2),
            Text(draft.merchant!, style: AppText.body(size: 13)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Konfirmasi'.tr,
                  expand: true,
                  onPressed: () => _confirm(context, controller),
                ),
              ),
              TextButton(
                onPressed: () => _edit(context, controller),
                child: Text(
                  'Edit'.tr,
                  style: AppText.body(size: 12.5, color: AppColors.ink),
                ),
              ),
              TextButton(
                onPressed: () => controller.dismiss(draft),
                child: Text(
                  'Abaikan'.tr,
                  style: AppText.body(size: 12.5, color: AppColors.mut),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
