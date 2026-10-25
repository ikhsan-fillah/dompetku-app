import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Geser kartu ke kiri untuk **Edit** dan **Hapus**. Satu pola untuk semua
/// daftar (transaksi, anggaran, tabungan, berulang, kategori) supaya tombol
/// geser selalu sama; aksi lain (arsip, duplikat) ada di lembar Edit.
///
/// Kartu dalam satu [groupTag] saling menutup: membuka satu kartu menutup
/// kartu lain yang sedang terbuka.
class SwipeActions extends StatelessWidget {
  const SwipeActions({
    super.key,
    required this.child,
    required this.onEdit,
    this.onDelete,
    this.groupTag,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final VoidCallback onEdit;

  /// Null: hanya tombol Edit (mis. kategori penampung).
  final VoidCallback? onDelete;
  final Object? groupTag;

  /// Sudut tombol paling kanan, mengikuti sudut kartu.
  final double radius;

  static const double _actionWidth = 72;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final count = onDelete == null ? 1 : 2;
        final ratio = box.maxWidth.isFinite && box.maxWidth > 0
            ? (_actionWidth * count / box.maxWidth).clamp(0.15, 0.6)
            : 0.2 * count;
        return Slidable(
          groupTag: groupTag,
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: ratio,
            children: [
              _SwipeButton(
                label: 'Edit'.tr,
                icon: LucideIcons.pencil,
                background: AppColors.accentSoft,
                foreground: AppColors.accent,
                radius: onDelete == null
                    ? BorderRadius.horizontal(right: Radius.circular(radius))
                    : BorderRadius.zero,
                onPressed: onEdit,
              ),
              if (onDelete != null)
                _SwipeButton(
                  label: 'Hapus'.tr,
                  icon: LucideIcons.trash2,
                  background: AppColors.spend,
                  foreground: AppColors.card,
                  radius: BorderRadius.horizontal(
                    right: Radius.circular(radius),
                  ),
                  onPressed: () {
                    onDelete!();
                  },
                ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _SwipeButton extends StatelessWidget {
  const _SwipeButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.radius = BorderRadius.zero,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (_) => onPressed(),
      backgroundColor: background,
      foregroundColor: foreground,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppText.body(
                size: 11,
                weight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
