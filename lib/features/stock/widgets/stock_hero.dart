import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Blok tinta di puncak halaman Saham, sama bentuknya dengan blok total di
/// halaman Tabungan: label kecil, angka atau judul besar, lalu keterangan.
class StockHero extends StatelessWidget {
  const StockHero({
    super.key,
    required this.label,
    required this.title,
    required this.caption,
  });

  final String label;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.paper.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label(color: muted, size: 11.5)),
          const SizedBox(height: 6),
          Text(title, style: AppText.display(size: 28, color: AppColors.paper)),
          const SizedBox(height: 6),
          Text(
            caption,
            style: AppText.body(size: 12.5, color: muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
