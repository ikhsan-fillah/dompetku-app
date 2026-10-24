import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/settings_tile.dart';
import '../controllers/backup_controller.dart';
import '../services/backup_service.dart';
import '../services/excel_export.dart';

/// Cadangan data: satu berkas .tally yang disimpan sendiri (tanpa akun dan
/// cloud), pulihkan dengan pratinjau, dan ekspor transaksi ke Excel.
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}.'
      '${value.minute.toString().padLeft(2, '0')}';

  Future<void> _backup(BackupController controller) async {
    final error = await controller.createBackup();
    if (error != null) {
      AppToast.show(title: error, kind: ToastKind.error);
    }
  }

  Future<void> _restore(
    BuildContext context,
    BackupController controller,
  ) async {
    final BackupPreview? preview;
    try {
      preview = await controller.pickBackup();
    } on BackupFormatException catch (error) {
      AppToast.show(title: error.message, kind: ToastKind.error);
      return;
    } catch (_) {
      AppToast.show(
        title: 'Berkas tidak bisa dibaca.'.tr,
        kind: ToastKind.error,
      );
      return;
    }
    if (preview == null || !context.mounted) return;
    final created = preview.createdAt;
    final ok = await showAppConfirm(
      context,
      title: 'Pulihkan cadangan ini?'.tr,
      message:
          'Cadangan @date berisi @summary. Semua data di HP ini akan diganti.'
              .trParams({
                'date': '${DateLabel.day(created)}, ${_time(created)}',
                'summary': BackupController.summary(preview.count),
              }),
      confirmLabel: 'Ganti data'.tr,
      danger: true,
    );
    if (!ok) return;
    final error = await controller.restore(preview);
    AppToast.show(
      title: error ?? 'Data dipulihkan'.tr,
      message: error == null ? BackupController.summary(preview.count) : null,
      kind: error == null ? ToastKind.success : ToastKind.error,
    );
  }

  Future<void> _export(BackupController controller) async {
    final error = await controller.exportExcel();
    if (error != null) {
      AppToast.show(title: error, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BackupController>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(title: 'Cadangan data'.tr),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  40,
                ),
                children: [
                  Obx(
                    () => _LastBackupCard(
                      at: controller.lastBackupAt.value,
                      summary: BackupController.summary(controller.countOf),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => AppCard(
                      child: Column(
                        children: [
                          SettingsTile(
                            icon: LucideIcons.archive,
                            title: 'Buat cadangan (.tally)'.tr,
                            subtitle: 'Simpan ke Drive, WhatsApp, atau file'.tr,
                            iconBackground: AppColors.paper2,
                            iconColor: AppColors.ink,
                            trailing: const Icon(
                              LucideIcons.chevronRight,
                              color: AppColors.mut,
                              size: 18,
                            ),
                            onTap: controller.busy.value
                                ? null
                                : () => _backup(controller),
                          ),
                          SettingsTile(
                            icon: LucideIcons.archiveRestore,
                            title: 'Pulihkan dari cadangan'.tr,
                            subtitle: 'Data di HP ini akan diganti'.tr,
                            iconBackground: AppColors.spendSoft,
                            iconColor: AppColors.spend,
                            showDivider: false,
                            trailing: const Icon(
                              LucideIcons.chevronRight,
                              color: AppColors.mut,
                              size: 18,
                            ),
                            onTap: controller.busy.value
                                ? null
                                : () => _restore(context, controller),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.earnSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                LucideIcons.sheet,
                                size: 19,
                                color: AppColors.earn,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ekspor transaksi ke Excel'.tr,
                                    style: AppText.body(
                                      size: 14,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Buka di Excel atau Google Sheets'.tr,
                                    style: AppText.body(
                                      size: 12,
                                      color: AppColors.mut,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => Row(
                            children: [
                              for (final value in ExportPeriod.values) ...[
                                if (value != ExportPeriod.values.first)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: _PeriodPill(
                                    label: switch (value) {
                                      ExportPeriod.thisMonth => 'Bulan ini'.tr,
                                      ExportPeriod.threeMonths => '3 bulan'.tr,
                                      ExportPeriod.all => 'Semua'.tr,
                                    },
                                    selected: controller.period.value == value,
                                    onTap: () =>
                                        controller.period.value = value,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => AppButton(
                            label: 'Bagikan file .xlsx'.tr,
                            icon: LucideIcons.share2,
                            loading: controller.busy.value,
                            onPressed: () => _export(controller),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tally tanpa akun dan tanpa cloud, jadi cadangan adalah satu berkas yang kamu simpan sendiri. Foto struk tidak ikut dicadangkan.'
                        .tr,
                    style: AppText.body(size: 12, color: AppColors.mut),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastBackupCard extends StatelessWidget {
  const _LastBackupCard({required this.at, required this.summary});

  final DateTime? at;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.paper.withValues(alpha: 0.7);
    final at = this.at;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CADANGAN TERAKHIR'.tr,
            style: AppText.label(color: muted, size: 11.5),
          ),
          const SizedBox(height: 6),
          Text(
            at == null
                ? 'Belum pernah'.tr
                : '${DateLabel.day(at)}, ${BackupPage._time(at)}',
            style: AppText.display(size: 26, color: AppColors.paper),
          ),
          const SizedBox(height: 4),
          Text(summary, style: AppText.mono(size: 11.5, color: muted)),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.smallButton),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.smallButton),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 12.5,
            weight: FontWeight.w700,
            color: selected ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    ),
  );
}
