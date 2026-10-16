import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: AppColors.ink,
    ),
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
          title: Text(
            'Hapus semua data?',
            style: AppText.display(size: 20),
          ),
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
                'Tindakan ini menghapus seluruh data keuangan, pengaturan, dan kunci aman dari perangkat ini. Tindakan tidak dapat dibatalkan.',
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
                  labelText: 'Ketik HAPUS untuk melanjutkan',
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
                    setDialogState(() => canDelete = value == 'HAPUS'),
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
                'Batal',
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
                'Hapus semua data',
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
          _controller.error.value ?? 'Gagal menghapus semua data. Coba lagi.',
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
                        '1 dompet · data tersimpan di perangkat ini',
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
              const SectionHeader(title: 'Nama tampilan'),
              AppTextField(
                controller: _nameField,
                label: 'Nama',
                hint: 'Friend',
                prefixIcon: LucideIcons.user,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 6),
              Text(
                'Dipakai pada sapaan di Beranda. Kosongkan untuk memakai "Friend".',
                style: AppText.body(size: 10.5, color: AppColors.mut),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Simpan nama',
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
              const SectionHeader(title: 'Kelola'),
              SettingsTile(
                icon: LucideIcons.tag,
                title: 'Kategori',
                subtitle: 'Ikon, warna, urutan, favorit',
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: _openCategories,
              ),
              SettingsTile(
                icon: LucideIcons.chartPie,
                title: 'Laporan',
                subtitle: 'Perbandingan & insight',
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.report),
              ),
              SettingsTile(
                icon: LucideIcons.repeat,
                title: 'Recurring',
                subtitle: 'Tagihan dan langganan berulang',
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.recurring),
              ),
              SettingsTile(
                icon: LucideIcons.scanEye,
                title: 'Auto-detect',
                subtitle: 'Baca notifikasi pembayaran (Android)',
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.autoDetect),
              ),
              SettingsTile(
                icon: LucideIcons.bell,
                title: 'Drafts',
                subtitle: 'Detected from payment notifications',
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
              const SectionHeader(title: 'Tampilan & data'),
              SettingsTile(
                icon: LucideIcons.palette,
                title: 'Tema',
                subtitle: 'Terang (mode gelap tidak dipakai)',
                iconBackground: AppColors.paper2,
                iconColor: AppColors.ink,
                trailing: const SettingsBadge(
                  label: 'Terang',
                  background: AppColors.paper2,
                  foreground: AppColors.ink,
                ),
              ),
              Obx(
                () => SettingsTile(
                  icon: LucideIcons.trash2,
                  iconBackground: AppColors.spendSoft,
                  iconColor: AppColors.spend,
                  titleColor: AppColors.spend,
                  title: 'Hapus semua data',
                  subtitle: 'Tidak dapat dibatalkan',
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
              'Tally 1.0.0 · tanpa akun · tanpa cloud',
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
