import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/display_name.dart';
import '../controllers/profile_controller.dart';

/// Kartu profil: avatar, nama dengan pensil kecil di sudutnya, dan jumlah
/// transaksi. Mengetuk pensil mengubah nama langsung di kartu (✓ simpan,
/// ✕ batal).
class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key, required this.controller});

  final ProfileController controller;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  var _editing = false;

  ProfileController get _controller => widget.controller;

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    _field.text = _controller.displayName.value;
    _field.selection = TextSelection.collapsed(offset: _field.text.length);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _cancel() {
    _focus.unfocus();
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    await _controller.setDisplayName(_field.text);
    if (!mounted) return;
    _focus.unfocus();
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  size: 22,
                  weight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: _editing ? _editor() : _display()),
          ],
        ),
      ),
    );
  }

  Widget _display() {
    final count = _controller.transactionCount.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                _controller.greetingName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(size: 22, color: AppColors.paper),
              ),
            ),
            Positioned(
              right: -12,
              top: -14,
              child: Semantics(
                button: true,
                label: 'Ubah nama tampilan'.tr,
                child: InkResponse(
                  onTap: _startEditing,
                  radius: 16,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.paper.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.pencil,
                          size: 11,
                          color: AppColors.paper.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (count != null) ...[
          const SizedBox(height: 4),
          Text(
            count == 1
                ? '1 transaksi tercatat'.tr
                : '@count transaksi tercatat'.trParams({'count': '$count'}),
            style: AppText.body(
              size: 12,
              color: AppColors.paper.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget _editor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _field,
                focusNode: _focus,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(DisplayName.maxLength),
                ],
                onSubmitted: (_) => _save(),
                cursorColor: AppColors.paper,
                style: AppText.display(size: 22, color: AppColors.paper),
                decoration: InputDecoration(
                  // Tema memberi isian latar krem; di kartu tinta harus bening.
                  filled: false,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  hintText: DisplayName.fallback,
                  hintStyle: AppText.display(
                    size: 22,
                    color: AppColors.paper.withValues(alpha: 0.4),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.paper, width: 1.5),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.paper, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _RoundButton(
              icon: LucideIcons.check,
              label: 'Simpan nama'.tr,
              background: AppColors.paper,
              foreground: AppColors.ink,
              onTap: _save,
            ),
            const SizedBox(width: 6),
            _RoundButton(
              icon: LucideIcons.x,
              label: 'Batal'.tr,
              background: AppColors.paper.withValues(alpha: 0.14),
              foreground: AppColors.paper,
              onTap: _cancel,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Kosongkan untuk memakai "Friend"'.tr,
          style: AppText.body(
            size: 11.5,
            color: AppColors.paper.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: foreground),
      ),
    ),
  );
}
