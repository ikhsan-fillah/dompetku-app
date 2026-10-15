import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Ikon tombol bulat (spec §2.3 `iconbtn`): 38 x 38, radius 8, border 1px, latar kartu.
class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.smallButton),
        border: Border.all(color: AppColors.line),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(
          width: AppSpacing.iconButton,
          height: AppSpacing.iconButton,
        ),
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: foreground ?? AppColors.ink),
      ),
    );
  }
}
