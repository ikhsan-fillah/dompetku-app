import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

enum AppButtonKind { primary, soft, outline, danger }

/// Tombol utama aplikasi (spec §3.21). Bila [expand] true, letakkan di parent yang lebarnya terbatas.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = AppButtonKind.primary,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final look = _Look.of(kind);
    final radius = BorderRadius.circular(AppRadius.button);
    final enabled = onPressed != null && !loading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: look.foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: look.foreground),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: look.foreground,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: look.background,
            borderRadius: radius,
            border: look.border,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.buttonHeight,
                  minWidth: AppSpacing.minTap,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Look {
  const _Look({
    required this.foreground,
    required this.background,
    this.border,
  });

  final Color foreground;
  final Color background;
  final BoxBorder? border;

  static _Look of(AppButtonKind kind) => switch (kind) {
    AppButtonKind.primary => const _Look(
      foreground: AppColors.paper,
      background: AppColors.ink,
    ),
    AppButtonKind.soft => const _Look(
      foreground: AppColors.ink,
      background: AppColors.paper2,
    ),
    AppButtonKind.outline => const _Look(
      foreground: AppColors.ink,
      background: Colors.transparent,
      border: Border.fromBorderSide(BorderSide(color: AppColors.ink)),
    ),
    AppButtonKind.danger => const _Look(
      foreground: Colors.white,
      background: AppColors.spend,
    ),
  };
}
