import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/section_header.dart';
import '../controllers/profile_controller.dart';

/// Versi awal halaman Profil: mengatur nama tampilan untuk sapaan Beranda.
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

  Future<void> _save() async {
    await _controller.setDisplayName(_nameField.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nama tersimpan.')),
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
          color: AppColors.mintSoft,
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Masuk hanya dengan sidik jari atau wajah. Tanpa akun dan tanpa cloud.',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
