import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/services/app_version.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController _controller = Get.find<ProfileController>();
  Worker? _refreshWorker;

  @override
  void initState() {
    super.initState();
    _controller.loadTransactionCount();
    if (Get.isRegistered<DataRefreshService>()) {
      _refreshWorker = ever<int>(
        Get.find<DataRefreshService>().version,
        (_) => _controller.loadTransactionCount(),
      );
    }
  }

  @override
  void dispose() {
    _refreshWorker?.dispose();
    super.dispose();
  }

  static const _spinner = SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
  );

  static const _chevron = Icon(
    LucideIcons.chevronRight,
    color: AppColors.mut,
    size: 18,
  );

  void _openCategories() => Get.toNamed(AppRoutes.categories);

  Future<void> _confirmReset() async {
    final confirmationController = TextEditingController();
    var canDelete = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: 'Hapus semua data?'.tr,
          message:
              'Tindakan ini menghapus seluruh data keuangan, pengaturan, dan kunci aman dari perangkat ini. Tindakan tidak dapat dibatalkan.'
                  .tr,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.spendSoft,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.spend,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmationController,
                autofocus: true,
                style: AppText.body(size: 13),
                decoration: InputDecoration(
                  labelText: 'Ketik @word untuk melanjutkan'.trParams({
                    'word': 'HAPUS'.tr,
                  }),
                  labelStyle: AppText.body(size: 12, color: AppColors.ink2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: const BorderSide(color: AppColors.ink),
                  ),
                ),
                onChanged: (value) =>
                    setDialogState(() => canDelete = value == 'HAPUS'.tr),
              ),
            ],
          ),
          confirmLabel: 'Hapus semua data'.tr,
          confirmKind: AppButtonKind.danger,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: canDelete
              ? () => Navigator.of(dialogContext).pop(true)
              : null,
        ),
      ),
    );
    confirmationController.dispose();
    if (confirmed != true) return;

    final reset = await _controller.resetAllData();
    if (!mounted) return;
    if (reset) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    AppToast.show(
      context: context,
      title:
          _controller.error.value ??
          'Gagal menghapus semua data. Coba lagi.'.tr,
      kind: ToastKind.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        130,
      ),
      children: [
        ProfileHeader(controller: _controller),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Kelola'.tr),
              SettingsTile(
                icon: LucideIcons.tag,
                title: 'Kategori'.tr,
                subtitle: 'Ikon, warna, urutan, favorit'.tr,
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: _openCategories,
              ),
              SettingsTile(
                icon: LucideIcons.chartPie,
                title: 'Laporan'.tr,
                subtitle: 'Perbandingan & insight'.tr,
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.report),
              ),
              SettingsTile(
                icon: LucideIcons.repeat,
                title: 'Transaksi berulang'.tr,
                subtitle: 'Tagihan dan langganan berulang'.tr,
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.recurring),
              ),
              SettingsTile(
                icon: LucideIcons.chartColumn,
                title: 'Rekap'.tr,
                subtitle: 'Putar ulang bulan atau tahun mana pun'.tr,
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.recaps),
              ),
              SettingsTile(
                icon: LucideIcons.scanEye,
                title: 'Deteksi otomatis'.tr,
                subtitle: 'Baca notifikasi pembayaran (Android)'.tr,
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.autoDetect),
              ),
              SettingsTile(
                icon: LucideIcons.bell,
                title: 'Draf'.tr,
                subtitle: 'Terdeteksi dari notifikasi pembayaran'.tr,
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                showDivider: false,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.drafts),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Tampilan & data'.tr),
              SettingsTile(
                icon: LucideIcons.palette,
                title: 'Tema'.tr,
                subtitle: 'Terang (mode gelap tidak dipakai)'.tr,
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: SettingsBadge(
                  label: 'Terang'.tr,
                  background: AppColors.paper2,
                  foreground: AppColors.ink,
                ),
              ),
              Obx(
                () => SettingsTile(
                  icon: LucideIcons.languages,
                  title: 'Bahasa'.tr,
                  subtitle: 'Bahasa tampilan aplikasi'.tr,
                  trailing: _LanguageDropdown(
                    value: _controller.language.value,
                    onChanged: _controller.setLanguage,
                  ),
                ),
              ),
              Obx(
                () => SettingsTile(
                  icon: LucideIcons.vibrate,
                  title: 'Getaran'.tr,
                  subtitle: 'Getar halus saat simpan, pilih, dan hapus'.tr,
                  iconBackground: AppColors.paper2,
                  iconColor: AppColors.ink,
                  trailing: Switch.adaptive(
                    value: _controller.hapticsEnabled.value,
                    activeTrackColor: AppColors.ink,
                    activeThumbColor: AppColors.paper,
                    inactiveTrackColor: AppColors.line,
                    inactiveThumbColor: Colors.white,
                    trackOutlineColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    onChanged: _controller.setHapticsEnabled,
                  ),
                  onTap: () => _controller.setHapticsEnabled(
                    !_controller.hapticsEnabled.value,
                  ),
                ),
              ),
              Obx(
                () => SettingsTile(
                  icon: LucideIcons.eyeOff,
                  title: 'Sembunyikan nominal di widget'.tr,
                  subtitle: 'Widget layar utama menampilkan Rp ••••'.tr,
                  iconBackground: AppColors.paper2,
                  iconColor: AppColors.ink,
                  trailing: Switch.adaptive(
                    value: _controller.widgetHideAmounts.value,
                    activeTrackColor: AppColors.ink,
                    activeThumbColor: AppColors.paper,
                    inactiveTrackColor: AppColors.line,
                    inactiveThumbColor: Colors.white,
                    trackOutlineColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                    onChanged: _controller.setWidgetHideAmounts,
                  ),
                  onTap: () => _controller.setWidgetHideAmounts(
                    !_controller.widgetHideAmounts.value,
                  ),
                ),
              ),
              Obx(
                () => SettingsTile(
                  icon: LucideIcons.trash2,
                  iconBackground: AppColors.spendSoft,
                  iconColor: AppColors.spend,
                  titleColor: AppColors.spend,
                  title: 'Hapus semua data'.tr,
                  subtitle: 'Tidak dapat dibatalkan'.tr,
                  showDivider: false,
                  trailing: _controller.resettingData.value ? _spinner : null,
                  onTap: _controller.resettingData.value ? null : _confirmReset,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Tally @version · tanpa akun · tanpa cloud'.trParams({
                'version': AppVersion.name,
              }),
              style: AppText.mono(
                size: 10.5,
                weight: FontWeight.w400,
                color: AppColors.mut,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.value, required this.onChanged});

  final String value;
  final Future<bool> Function(String code) onChanged;

  static const _labels = {
    AppLanguage.indonesian: 'Indonesia',
    AppLanguage.english: 'English',
  };

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: value,
      isDense: true,
      borderRadius: BorderRadius.circular(AppRadius.field),
      dropdownColor: AppColors.card,
      icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.mut),
      style: AppText.body(size: 12.5, weight: FontWeight.w700),
      items: [
        for (final code in AppLanguage.options)
          DropdownMenuItem(value: code, child: Text(_labels[code]!)),
      ],
      onChanged: (code) {
        if (code != null && code != value) onChanged(code);
      },
    ),
  );
}
