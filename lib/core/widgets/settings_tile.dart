import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Baris pengaturan bergaya mockup: kotak ikon, judul, subjudul, dan aksi kanan.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconBackground = AppColors.mint,
    this.iconColor = AppColors.teal,
    this.titleColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconBackground;
  final Color iconColor;
  final Color? titleColor;
  final bool showDivider;

  static const _divider = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: _divider),
      ],
    );
  }
}

/// Lencana kecil untuk nilai singkat di sisi kanan [SettingsTile].
class SettingsBadge extends StatelessWidget {
  const SettingsBadge({
    super.key,
    required this.label,
    this.background = AppColors.mint,
    this.foreground = AppColors.teal,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
