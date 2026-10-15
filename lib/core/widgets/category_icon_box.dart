import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Kotak ikon kategori (spec §2.3 `ci`): radius 8, ikon putih, tanpa bayangan.
class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.smallButton),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}
