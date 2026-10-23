import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Ikon tombol bulat (spec §2.3 `iconbtn`): 38 x 38, radius 8, border 1px, latar kartu.
///
/// Kotak yang terlihat tepat [AppSpacing.iconButton]. Area ketuknya 44 x 44
/// dan tidak ikut membesarkan kotak (memakai `IconButton` biasa, kotaknya
/// melebar jadi 48 mengikuti area ketuk bawaan Material).
class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.foreground,
  });

  static const double _tapArea = 44;

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: _tapArea / 2,
          child: SizedBox(
            width: _tapArea,
            height: _tapArea,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background ?? AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.smallButton),
                  border: Border.all(color: AppColors.line),
                ),
                child: SizedBox(
                  width: AppSpacing.iconButton,
                  height: AppSpacing.iconButton,
                  child: Icon(
                    icon,
                    size: 18,
                    color: foreground ?? AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
