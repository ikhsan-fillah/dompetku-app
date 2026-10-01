import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/section_header.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/profile_controller.dart';

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

  static String _autoLockLabel(int seconds) {
    if (seconds == 0) return 'Langsung';
    return '${seconds ~/ 60} menit';
  }

  Future<void> _save() async {
    await _controller.setDisplayName(_nameField.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nama tersimpan.')));
  }

  Future<void> _setBiometric(bool value) async {
    final saved = await _controller.setBiometricEnabled(value);
    if (!mounted || saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.error.value ?? 'Gagal menyimpan pengaturan biometrik.',
        ),
      ),
    );
  }

  Future<void> _setAutoLock(int? value) async {
    if (value == null) return;
    final saved = await _controller.setAutoLockSeconds(value);
    if (!mounted || saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.error.value ?? 'Gagal menyimpan durasi kunci otomatis.',
        ),
      ),
    );
  }

  Future<void> _setTheme(String value) async {
    final saved = await _controller.setThemeMode(value);
    if (!mounted || saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_controller.error.value ?? 'Gagal menyimpan tema.')),
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

  Future<void> _lockApp() async {
    final locked = await _controller.lockApp();
    if (!mounted || !locked) {
      if (mounted && _controller.error.value != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_controller.error.value!)));
      }
      return;
    }
    Get.offAllNamed(AppRoutes.biometricUnlock);
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
      Get.offAllNamed('/login');
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
                  width: 56,
                  height: 56,
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
                      fontSize: 20,
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
                        'Halo, ${_controller.greetingName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Data tersimpan di perangkat ini',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
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
              const SectionHeader(title: 'Keamanan'),
              Obx(
                () => SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _controller.biometricEnabled.value,
                  onChanged: _controller.savingBiometric.value
                      ? null
                      : _setBiometric,
                  activeThumbColor: AppColors.teal,
                  secondary: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.teal,
                  ),
                  title: const Text('Kunci biometrik'),
                  subtitle: Text(
                    _controller.biometricEnabled.value
                        ? 'Aktif saat membuka aplikasi.'
                        : 'Tidak aktif untuk saat ini.',
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Obx(
                () => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.timer_outlined,
                    color: AppColors.teal,
                  ),
                  title: const Text('Kunci otomatis'),
                  subtitle: const Text('Setelah di latar belakang'),
                  trailing: DropdownButton<int>(
                    value: _controller.autoLockSeconds.value,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(18),
                    items: [
                      for (final seconds in ProfileController.autoLockOptions)
                        DropdownMenuItem<int>(
                          value: seconds,
                          child: Text(_autoLockLabel(seconds)),
                        ),
                    ],
                    onChanged: _controller.savingAutoLock.value
                        ? null
                        : _setAutoLock,
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Obx(
                () => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.lock_clock_outlined,
                    color: AppColors.teal,
                  ),
                  title: const Text('Kunci aplikasi sekarang'),
                  subtitle: const Text('Minta verifikasi sebelum membuka data'),
                  trailing: _controller.lockingApp.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _controller.lockingApp.value ? null : _lockApp,
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: AppColors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data keuangan tersimpan lokal di perangkat ini. DompetKu tidak menggunakan akun atau cloud.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Tampilan'),
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
              const SizedBox(height: 8),
              Text(
                'Sistem mengikuti mode terang atau gelap perangkat.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Ekspor data'),
              Text(
                'Simpan dan bagikan kategori, transaksi, serta anggaran sebagai berkas JSON sebelum menghapus data. Ekspor tetap lokal dan tidak dikirim ke layanan eksternal.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _controller.exportingData.value
                        ? null
                        : _exportData,
                    icon: _controller.exportingData.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined),
                    label: Text(
                      _controller.exportingData.value
                          ? 'Menyiapkan ekspor...'
                          : 'Simpan dan bagikan ekspor',
                    ),
                  ),
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
                  padding: const EdgeInsets.only(top: 12),
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
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Zona bahaya'),
              Text(
                'Hapus database, seluruh pengaturan, dan data aman dari perangkat ini. Setelahnya Anda perlu daftar ulang.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF43F5E),
                      side: const BorderSide(color: Color(0xFFF43F5E)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _controller.resettingData.value
                        ? null
                        : _confirmReset,
                    icon: _controller.resettingData.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: Text(
                      _controller.resettingData.value
                          ? 'Menghapus data...'
                          : 'Hapus semua data',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
