import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.gradient,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? background;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final iconColor = gradient != null || background != null
        ? Colors.white
        : AppColors.teal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (background ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.softShadow,
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}
