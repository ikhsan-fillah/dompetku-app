import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Chip urutan untuk app bar: ikon urut, label singkat pilihan aktif, dan
/// panah. Mengetuknya membuka menu kecil berisi label lengkap. Dipakai bersama
/// oleh daftar Transaksi dan Anggaran supaya tampilannya seragam.
class SortChip<T> extends StatelessWidget {
  const SortChip({
    super.key,
    required this.value,
    required this.options,
    required this.chipLabel,
    required this.menuLabel,
    required this.onSelected,
    required this.tooltip,
  });

  final T value;
  final List<T> options;

  /// Label singkat untuk chip (mis. "Terpakai").
  final String Function(T option) chipLabel;

  /// Label lengkap untuk baris menu (mis. "Terpakai tertinggi").
  final String Function(T option) menuLabel;
  final ValueChanged<T> onSelected;
  final String tooltip;

  static const _maxChipWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      offset: const Offset(0, -2),
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x291A2724),
      elevation: 8,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: option == value
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
                Flexible(
                  child: Text(
                    menuLabel(option),
                    style: AppText.body(
                      size: 13.5,
                      weight: option == value
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: option == value ? AppColors.ink : AppColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      // Area ketuk 44 px; tinggi, warna, dan garis chip sama dengan
      // [AppBarIconButton] di sebelahnya (mis. tombol arsip).
      child: Container(
        height: 44,
        alignment: Alignment.center,
        child: Container(
          height: AppSpacing.iconButton,
          constraints: const BoxConstraints(maxWidth: _maxChipWidth),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.smallButton),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.arrowUpDown,
                size: 15,
                color: AppColors.ink,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  chipLabel(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 12.5, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
