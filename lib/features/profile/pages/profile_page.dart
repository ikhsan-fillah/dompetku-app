import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/profile_controller.dart';
import '../../shell/controllers/main_shell_controller.dart';

/// Halaman Profil dan pengaturan perangkat DompetKu.
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
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  static const _chevron = Icon(
    Icons.chevron_right_rounded,
    color: AppColors.muted,
  );

  Future<void> _save() async {
    await _controller.setDisplayName(_nameField.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nama tersimpan.')));
  }

  Future<void> _setTheme(String value) async {
    final saved = await _controller.setThemeMode(value);
    if (!mounted || saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_controller.error.value ?? 'Gagal menyimpan tema.'),
      ),
    );
  }

  Future<void> _exportData() async {
    final exported = await _controller.exportData();
    if (!mounted) return;

    final message = exported
        ? _controller.exportSuccess.value ?? 'Data berhasil diekspor.'
        : _controller.exportError.value ?? 'Gagal mengekspor data. Coba lagi.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCategories() {
    Get.toNamed(AppRoutes.categories);
  }

  void _openBudgetTab() {
    // Profil adalah tab di dalam shell, cukup pindah tab (tanpa Get.back()).
    if (Get.isRegistered<MainShellController>()) {
      Get.find<MainShellController>().select(2);
    }
  }

  Future<void> _confirmReset() async {
    final confirmationController = TextEditingController();
    var canDelete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Hapus semua data?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tindakan ini menghapus seluruh data keuangan, pengaturan, dan kunci aman dari perangkat ini. Tindakan tidak dapat dibatalkan.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmationController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Ketik HAPUS untuk melanjutkan',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setDialogState(() => canDelete = value == 'HAPUS');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: canDelete
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: const Text('Hapus semua data'),
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
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        130,
      ),
      children: [
        Text('Profil', style: textTheme.titleLarge),
        const SizedBox(height: 14),
        AppCard(
          gradient: AppColors.heroGradient,
          radius: AppRadius.hero,
          padding: const EdgeInsets.all(20),
          child: Obx(
            () => Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.amber, AppColors.coral],
                    ),
                  ),
                  child: Text(
                    _controller.initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
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
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 dompet · data tersimpan di perangkat ini',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
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
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 6),
              Text(
                'Dipakai pada sapaan di Beranda. Kosongkan untuk memakai "Friend".',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Simpan nama',
                icon: Icons.check_rounded,
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
                icon: Icons.label_outline_rounded,
                title: 'Kategori',
                subtitle: 'Ikon, warna, urutan, favorit',
                trailing: _chevron,
                onTap: _openCategories,
              ),
              SettingsTile(
                icon: Icons.track_changes_rounded,
                title: 'Anggaran',
                subtitle: 'Batas bulanan & peringatan',
                trailing: _chevron,
                onTap: _openBudgetTab,
              ),
              SettingsTile(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Laporan',
                subtitle: 'Perbandingan & insight',
                showDivider: false,
                trailing: _chevron,
                onTap: () => Get.toNamed(AppRoutes.report),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Tampilan & data'),
              const SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Tema',
                subtitle: 'Ikuti sistem, terang, atau gelap',
                showDivider: false,
              ),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<String>(
                        value: 'system',
                        label: Text('Sistem'),
                        icon: Icon(Icons.brightness_auto_rounded),
                      ),
                      ButtonSegment<String>(
                        value: 'light',
                        label: Text('Terang'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment<String>(
                        value: 'dark',
                        label: Text('Gelap'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {_controller.themeMode.value},
                    onSelectionChanged: _controller.savingTheme.value
                        ? null
                        : (selection) => _setTheme(selection.first),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Obx(
                () => SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: 'Ekspor data',
                  subtitle: 'Simpan cadangan di perangkat',
                  trailing: _controller.exportingData.value
                      ? _spinner
                      : _chevron,
                  onTap: _controller.exportingData.value ? null : _exportData,
                ),
              ),
              Obx(() {
                final success = _controller.exportSuccess.value;
                final exportError = _controller.exportError.value;
                if (success == null && exportError == null) {
                  return const SizedBox.shrink();
                }
                final isSuccess = success != null;
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSuccess
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        color: isSuccess ? AppColors.emerald : AppColors.coral,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          success ?? exportError!,
                          style: textTheme.bodySmall?.copyWith(
                            color: isSuccess ? AppColors.teal : AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Obx(
                () => SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconBackground: AppColors.coralSoft,
                  iconColor: AppColors.coral,
                  titleColor: AppColors.coral,
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
          child: Text(
            'DompetKu 1.0.0 · Privasi: tanpa cloud',
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}
