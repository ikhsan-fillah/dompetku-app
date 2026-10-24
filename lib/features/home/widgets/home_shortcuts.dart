import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/app_haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Pintasan ke fitur penting yang juga ada di Profil. Dibatasi empat kartu
/// dalam satu baris; Profil tetap menjadi daftar lengkap.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key});

  static final _items = <(String, IconData, Color, String)>[
    ('Laporan', LucideIcons.chartPie, AppColors.accent, AppRoutes.report),
    ('Tabungan', LucideIcons.piggyBank, AppColors.earn, AppRoutes.goals),
    ('Berulang', LucideIcons.repeat, AppColors.catBills, AppRoutes.recurring),
    ('Rekap', LucideIcons.chartColumn, AppColors.catFood, AppRoutes.recaps),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gap),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _ShortcutCard(item: _items[i])),
          ],
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.item});

  final (String, IconData, Color, String) item;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, route) = item;
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppHaptics.select();
          Get.toNamed(route);
        },
        child: Semantics(
          button: true,
          label: label.tr,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 7),
                Text(
                  label.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 11, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
