import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Satu tombol aksi kartu (mis. Edit, Hapus).
class CardAction {
  const CardAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Merah untuk aksi yang menghapus.
  final bool danger;
}

/// Deretan tombol aksi yang muncul di bawah kartu saat diketuk. Dipakai kartu
/// transaksi, transaksi berulang, dan anggaran supaya polanya seragam.
class CardActionBar extends StatelessWidget {
  const CardActionBar({
    super.key,
    required this.expanded,
    required this.actions,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  final bool expanded;
  final List<CardAction> actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: expanded
          ? Padding(
              padding: padding,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final action in actions) _ActionButton(action: action),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final CardAction action;

  @override
  Widget build(BuildContext context) {
    final foreground = action.danger ? AppColors.spend : AppColors.ink;
    return TextButton.icon(
      onPressed: action.onTap,
      icon: Icon(action.icon, size: 13, color: foreground),
      label: Text(action.label),
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: action.danger ? AppColors.spendSoft : AppColors.paper2,
        minimumSize: const Size(48, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        textStyle: AppText.body(size: 11, weight: FontWeight.w700),
      ),
    );
  }
}
