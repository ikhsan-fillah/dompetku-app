import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Bottom navigation melayang dengan tombol tambah di tengah.
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

  static const double _fabOverflow = 30;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.navHeight + _fabOverflow,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: AppSpacing.navHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x380F766E),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _NavButton(
                    label: 'Beranda',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    selected: currentIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _NavButton(
                    label: 'Transaksi',
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    selected: currentIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  const SizedBox(width: 78),
                  _NavButton(
                    label: 'Anggaran',
                    icon: Icons.pie_chart_outline_rounded,
                    activeIcon: Icons.pie_chart_rounded,
                    selected: currentIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _NavButton(
                    label: 'Profil',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    selected: currentIndex == 3,
                    onTap: () => onSelect(3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(top: 0, child: _AddButton(onTap: onAdd)),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal : const Color(0xFF94A3B8);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.mint : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(color: AppColors.background, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x730F766E),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
