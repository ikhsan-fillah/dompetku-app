import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonKind { primary, soft, outline, danger }

/// Tombol utama aplikasi. Bila [expand] true, letakkan di parent yang lebarnya terbatas.
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
              strokeWidth: 2.4,
              color: look.foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: look.foreground),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
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
            gradient: look.gradient,
            color: look.gradient == null ? look.background : null,
            borderRadius: radius,
            border: look.border,
            boxShadow: look.shadow,
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
                    horizontal: 20,
                    vertical: 12,
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
    this.gradient,
    this.background,
    this.border,
    this.shadow,
  });

  final Color foreground;
  final Gradient? gradient;
  final Color? background;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;

  static _Look of(AppButtonKind kind) => switch (kind) {
    AppButtonKind.primary => const _Look(
      foreground: Colors.white,
      gradient: AppColors.primaryGradient,
      shadow: [
        BoxShadow(
          color: Color(0x590F766E),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    AppButtonKind.soft => const _Look(
      foreground: AppColors.teal,
      background: AppColors.mint,
    ),
    AppButtonKind.outline => const _Look(
      foreground: AppColors.teal,
      background: AppColors.surface,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.tealLight, width: 1.5),
      ),
    ),
    AppButtonKind.danger => const _Look(
      foreground: Colors.white,
      gradient: LinearGradient(colors: [Color(0xFFE11D48), AppColors.coral]),
      shadow: [
        BoxShadow(
          color: Color(0x59F43F5E),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
  };
}
