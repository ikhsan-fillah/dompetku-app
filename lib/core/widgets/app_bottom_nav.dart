import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Bottom navigation melayang dengan tombol tambah di tengah (spec §3.14).
/// Indeks tab: 0 Beranda, 1 Transaksi, 2 Anggaran, 3 Profil.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.navHeight + AppSpacing.fabOverflow,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: AppSpacing.navInset,
            right: AppSpacing.navInset,
            bottom: AppSpacing.navInset,
            height: AppSpacing.navHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.nav),
                border: Border.all(color: AppColors.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x241A2724),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _NavButton(
                    label: 'Beranda',
                    icon: LucideIcons.house,
                    selected: currentIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _NavButton(
                    label: 'Transaksi',
                    icon: LucideIcons.listOrdered,
                    selected: currentIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  const SizedBox(width: 74),
                  _NavButton(
                    label: 'Anggaran',
                    icon: LucideIcons.chartPie,
                    selected: currentIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _NavButton(
                    label: 'Profil',
                    icon: LucideIcons.user,
                    selected: currentIndex == 3,
                    onTap: () => onSelect(3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _AddButton(onTap: onAdd),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.mut;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.smallButton),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.paper2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.smallButton),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: AppText.body(
                  size: 10,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tambah transaksi',
      child: Container(
        width: AppSpacing.fabSize,
        height: AppSpacing.fabSize,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.fab),
          border: Border.all(color: AppColors.paper, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x590E5E55),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.fab),
            onTap: onTap,
            child: const Icon(
              LucideIcons.plus,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
