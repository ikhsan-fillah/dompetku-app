import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Judul kartu (spec §3.4 `card h3`): Manrope 13/700, link kanan dengan underline.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w700,
                letterSpacing: 0.13,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink2,
                minimumSize: const Size(AppSpacing.minTap, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                actionLabel!,
                style:
                    AppText.body(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.ink2,
                    ).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.line,
                      decorationThickness: 1,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
