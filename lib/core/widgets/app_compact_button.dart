import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

enum AppCompactButtonKind { primary, soft }

/// Tombol ringkas setinggi tombol ikon app bar (38, area ketuk 44), untuk
/// app bar dan aksi di dalam kartu. Selalu berlatar supaya terbaca sebagai
/// tombol: [AppCompactButtonKind.primary] hitam untuk aksi utama,
/// [AppCompactButtonKind.soft] abu kertas untuk aksi pendamping.
class AppCompactButton extends StatelessWidget {
  const AppCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = AppCompactButtonKind.primary,
    this.foreground,
    this.expand = false,
  });

  static const double _tapArea = 44;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppCompactButtonKind kind;

  /// Warna teks dan ikon khusus (mis. abu untuk Abaikan).
  final Color? foreground;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final primary = kind == AppCompactButtonKind.primary;
    final fg = foreground ?? (primary ? AppColors.paper : AppColors.ink);
    final radius = BorderRadius.circular(AppRadius.smallButton);
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        // Area ketuk 44 di luar, riak hanya di badan tombol 38.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox(
            height: _tapArea,
            child: Center(
              child: Material(
                color: primary ? AppColors.ink : AppColors.paper2,
                borderRadius: radius,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: radius,
                  child: Container(
                    height: AppSpacing.iconButton,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: expand
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 15, color: fg),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ),
                      ],
                    ),
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
