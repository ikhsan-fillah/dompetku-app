import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController _controller = Get.find<ProfileController>();
  late final TextEditingController _nameField;
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _nameField = TextEditingController(text: _controller.displayName.value);
    _worker = ever<String>(_controller.displayName, (value) {
      if (_nameField.text.isEmpty) _nameField.text = value;
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _nameField.dispose();
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

  Future<void> _save() async {
    await _controller.setDisplayName(_nameField.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  void _openCategories() => Get.toNamed(AppRoutes.categories);

  Future<void> _confirmReset() async {
    final confirmationController = TextEditingController();
    var canDelete = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.hero),
            side: const BorderSide(color: AppColors.line),
          ),
          title: Text('Hapus semua data?'.tr, style: AppText.display(size: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 14),
              Text(
                'Tindakan ini menghapus seluruh data keuangan, pengaturan, dan kunci aman dari perangkat ini. Tindakan tidak dapat dibatalkan.'
                    .tr,
                style: AppText.body(
                  size: 13,
                  color: AppColors.mut,
                  height: 1.45,
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
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Batal'.tr,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.spend,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.paper2,
                disabledForegroundColor: AppColors.mut,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              onPressed: canDelete
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: Text(
                'Hapus semua data'.tr,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: canDelete ? Colors.white : AppColors.mut,
                ),
              ),
            ),
          ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.error.value ??
              'Gagal menghapus semua data. Coba lagi.'.tr,
        ),
      ),
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
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.gap),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.hero),
          ),
          child: Obx(
            () => Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _controller.initial,
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controller.greetingName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          size: 18,
                          color: AppColors.paper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 dompet · data tersimpan di perangkat ini'.tr,
                        style: AppText.body(
                          size: 11,
                          color: AppColors.paper.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Nama tampilan'.tr),
              AppTextField(
                controller: _nameField,
                label: 'Nama'.tr,
                hint: 'Friend',
                prefixIcon: LucideIcons.user,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 6),
              Text(
                'Dipakai pada sapaan di Beranda. Kosongkan untuk memakai "Friend".'
                    .tr,
                style: AppText.body(size: 10.5, color: AppColors.mut),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Simpan nama'.tr,
                icon: LucideIcons.check,
                onPressed: _save,
              ),
            ],
          ),
        ),
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
              'Tally 1.0.0 · tanpa akun · tanpa cloud'.tr,
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
