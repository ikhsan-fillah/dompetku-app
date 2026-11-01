import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../services/price_analysis.dart';

/// Label, ikon, dan warna tiap tren. Warna hanya penanda; arti utamanya ada
/// di teks dan ikon.
(String, IconData, Color, Color) trendStyle(TrendKind kind) => switch (kind) {
  TrendKind.naik => (
    'Tren naik'.tr,
    LucideIcons.trendingUp,
    AppColors.earn,
    AppColors.earnSoft,
  ),
  TrendKind.turun => (
    'Tren turun'.tr,
    LucideIcons.trendingDown,
    AppColors.spend,
    AppColors.spendSoft,
  ),
  TrendKind.campuran => (
    'Tren campuran'.tr,
    LucideIcons.activity,
    AppColors.ink2,
    AppColors.paper2,
  ),
};

/// Label kecil tren di sebelah status aktif pada kartu watchlist.
class TrendPill extends StatelessWidget {
  const TrendPill({super.key, required this.kind});

  final TrendKind kind;

  @override
  Widget build(BuildContext context) {
    final (label, icon, fg, bg) = trendStyle(kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          // Di kartu sempit atau teks besar, label boleh turun baris.
          Flexible(
            child: Text(
              label,
              style: AppText.body(
                size: 10.5,
                weight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
