import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Blok tinta di puncak halaman Saham, sama bentuknya dengan blok total di
/// halaman Tabungan: label kecil, angka atau judul besar, lalu keterangan.
/// [trailing] duduk di sebelah kanan judul, [footer] di bawah keterangan.
class StockHero extends StatelessWidget {
  const StockHero({
    super.key,
    required this.label,
    required this.title,
    required this.caption,
    this.trailing,
    this.footer,
  });

  final String label;
  final String title;
  final String caption;
  final Widget? trailing;
  final Widget? footer;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppText.label(color: muted, size: 11.5)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.display(size: 28, color: AppColors.paper),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: AppText.body(size: 12.5, color: muted, height: 1.45),
          ),
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

/// Lencana perubahan harga di atas blok tinta atau kartu: panah, persen, dan
/// warna naik atau turun. Arahnya juga tertulis lewat tanda +/-.
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.percent, required this.text});

  final double percent;
  final String text;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (percent) {
      > 0 => (AppColors.earnSoft, AppColors.earn, LucideIcons.trendingUp),
      < 0 => (AppColors.spendSoft, AppColors.spend, LucideIcons.trendingDown),
      _ => (AppColors.paper2, AppColors.ink2, LucideIcons.minus),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppText.mono(
              size: 12.5,
              weight: FontWeight.w700,
              color: foreground,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
