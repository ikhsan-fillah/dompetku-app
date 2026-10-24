import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/duotone_icon.dart';
import '../theme/category_style.dart';

/// Kotak ikon kategori: latar warna kategori yang lembut dengan ikon berwarna.
///
/// [CategoryIconBox.category] memakai ikon Phosphor duotone (isian lembut +
/// garis tegas) menurut `icon_key` kategori. Konstruktor biasa menerima ikon
/// apa pun (mis. panah pemasukan) dengan gaya kotak yang sama.
class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({
    super.key,
    required IconData this.icon,
    required this.color,
    this.size = 36,
  }) : iconKey = null;

  const CategoryIconBox.category({
    super.key,
    required String this.iconKey,
    required this.color,
    this.size = 36,
  }) : icon = null;

  final IconData? icon;
  final String? iconKey;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = size * 0.56;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.smallButton + 2),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: iconKey != null
          ? DuotoneIconView(
              CategoryStyle.duotone(iconKey!),
              color: color,
              size: glyph,
            )
          : Icon(icon, color: color, size: size * 0.46),
    );
  }
}
