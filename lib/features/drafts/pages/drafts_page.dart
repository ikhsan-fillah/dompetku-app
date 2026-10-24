import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../category/models/category_model.dart';
import '../../category/widgets/category_picker.dart';
import '../controllers/draft_controller.dart';
import '../models/draft_model.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';

/// Daftar draft hasil deteksi. Confirm, Edit (lewat Confirm), atau Dismiss.
class DraftsPage extends StatelessWidget {
  const DraftsPage({super.key});

  Future<void> _confirmAll(
    BuildContext context,
    DraftController controller,
  ) async {
    final result = await controller.confirmAll();
    if (!context.mounted) return;
    AppToast.show(
      context: context,
      title: '@count draf dikonfirmasi'.trParams({
        'count': '${result.confirmed}',
      }),
      message: result.skipped == 0
          ? null
          : '@count draf belum berkategori, konfirmasi satu per satu.'.trParams(
              {'count': '${result.skipped}'},
            ),
      kind: result.skipped == 0 ? ToastKind.success : ToastKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DraftController>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              final count = controller.state.value.data?.length ?? 0;
              return AppTitleBar(
                title: 'Draf'.tr,
                // Tombol sama dengan Konfirmasi di kartu draf.
                action: count > 1
                    ? AppButton(
                        label: 'Konfirmasi semua'.tr,
                        icon: LucideIcons.checkCheck,
                        expand: false,
                        onPressed: () => _confirmAll(context, controller),
                      )
                    : null,
              );
            }),
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

  /// Waktu notifikasi terbaca; tanggal ini yang dipakai transaksinya.
  String get _when {
    final at = draft.detectedAt.toLocal();
    final time =
        '${at.hour.toString().padLeft(2, '0')}.'
        '${at.minute.toString().padLeft(2, '0')}';
    return '${DateLabel.relativeDay(at)} · $time';
  }

  void _showError(BuildContext context, String message) {
    AppToast.show(context: context, title: message, kind: ToastKind.error);
  }

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
      _showError(
        context,
        controller.error.value ?? 'Gagal mengonfirmasi. Coba lagi.'.tr,
      );
    }
  }

  /// Ubah nama, nominal, dan kategori dalam satu dialog, lalu konfirmasi.
  Future<void> _edit(BuildContext context, DraftController controller) async {
    final categories = await controller.expenseCategories(kind: draft.kind);
    if (!context.mounted) return;
    final result = await showDialog<_DraftEdit>(
      context: context,
      builder: (_) => _EditDraftDialog(draft: draft, categories: categories),
    );
    if (result == null || !context.mounted) return;
    final saved = await controller.editAndConfirm(
      draft,
      amount: result.amount,
      merchant: result.merchant,
      categoryId: result.categoryId,
    );
    if (!saved && context.mounted) {
      _showError(
        context,
        controller.error.value ?? 'Gagal menyimpan perubahan.'.tr,
      );
    }
  }

  /// Lembar pilih kategori (ikon + nama), sama dengan lembar lain di app.
  Future<int?> _pickCategory(
    BuildContext context,
    DraftController controller,
  ) async {
    final categories = await controller.expenseCategories(kind: draft.kind);
    if (!context.mounted) return null;
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(color: AppColors.line),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.page,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih kategori'.tr, style: AppText.display(size: 22)),
            const SizedBox(height: 4),
            Text(
              '@amount · @when'.trParams({
                'amount': formatIdr(draft.amount),
                'when': _when,
              }),
              style: AppText.body(size: 12.5, color: AppColors.mut),
            ),
            const SizedBox(height: 16),
            CategoryPicker(
              options: categories,
              selected: null,
              wrap: true,
              onSelect: (id) => Navigator.of(sheetContext).pop(id),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.source.tr,
                  style: AppText.body(size: 11, color: AppColors.mut),
                ),
              ),
              const Icon(LucideIcons.clock, size: 12, color: AppColors.mut),
              const SizedBox(width: 4),
              Text(
                _when,
                style: AppText.mono(
                  size: 11,
                  color: AppColors.mut,
                  letterSpacing: 0,
                ),
              ),
            ],
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

/// Hasil dialog Ubah draf.
class _DraftEdit {
  const _DraftEdit({
    required this.merchant,
    required this.amount,
    required this.categoryId,
  });

  final String merchant;
  final int amount;
  final int categoryId;
}

/// Dialog Ubah draf: nama, nominal, dan kategori langsung di satu tempat.
/// Tombol simpan aktif setelah nominal valid dan kategori dipilih.
class _EditDraftDialog extends StatefulWidget {
  const _EditDraftDialog({required this.draft, required this.categories});

  final DraftModel draft;
  final List<CategoryModel> categories;

  @override
  State<_EditDraftDialog> createState() => _EditDraftDialogState();
}

class _EditDraftDialogState extends State<_EditDraftDialog> {
  late final _name = TextEditingController(text: widget.draft.merchant ?? '');
  late final _amount = TextEditingController(
    text: formatIdrPlain(widget.draft.amount),
  );
  late int? _categoryId = widget.draft.categoryId;

  int? get _value =>
      int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), ''));

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final categoryId = _categoryId;
    final valid = value != null && value > 0 && categoryId != null;
    return AppDialog(
      title: 'Ubah draf'.tr,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: 'Nama'.tr),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [_Thousands()],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Jumlah (IDR)'.tr,
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Kategori'.tr,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 8),
          CategoryPicker(
            options: widget.categories,
            selected: categoryId,
            onSelect: (id) => setState(() => _categoryId = id),
          ),
        ],
      ),
      confirmLabel: 'Simpan & konfirmasi'.tr,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: valid
          ? () => Navigator.of(context).pop(
              _DraftEdit(
                merchant: _name.text,
                amount: value,
                categoryId: categoryId,
              ),
            )
          : null,
    );
  }
}

class _Thousands extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = formatIdrPlain(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
