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
    this.live = false,
  });

  final String label;
  final String title;
  final String caption;
  final Widget? trailing;
  final Widget? footer;

  /// Titik hijau di sebelah label: angka di blok ini masih bisa berubah
  /// (hari bursa berjalan). Labelnya sendiri juga menyebut "berjalan".
  final bool live;

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
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppText.label(color: muted, size: 11.5),
                ),
              ),
              if (live) ...[
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.liveDot,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
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

/// Angka harga satu hari di blok tinta, dibagi ke kolom yang dipisah garis
/// tipis (mis. buka, tertinggi, terendah, volume).
class HeroStats extends StatelessWidget {
  const HeroStats({super.key, required this.items});

  final List<(String label, String value)> items;

  @override
  Widget build(BuildContext context) {
    final divider = AppColors.paper.withValues(alpha: 0.16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: divider),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, (label, value)) in items.indexed) ...[
                if (index > 0) VerticalDivider(width: 17, color: divider),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        style: AppText.label(
                          size: 10,
                          color: AppColors.paper.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: AppText.mono(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.paper,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
