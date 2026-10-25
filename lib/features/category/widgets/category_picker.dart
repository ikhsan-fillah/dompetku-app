import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../models/category_model.dart';

/// Pilihan kategori berupa ikon dengan nama di bawahnya. Dipakai di Catat
/// Keuangan dan Draf supaya cara memilih kategori sama di mana pun.
///
/// Bawaannya satu baris yang digeser ke samping; [wrap] menyusunnya
/// beberapa baris (untuk lembar yang lebar).
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.wrap = false,
  });

  final List<CategoryModel> options;
  final int? selected;
  final ValueChanged<int> onSelect;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Belum ada kategori untuk jenis ini.'.tr,
          style: AppText.body(size: 12, color: AppColors.mut),
        ),
      );
    }
    final choices = [
      for (final category in options)
        CategoryChoice(
          category: category,
          selected: category.id == selected,
          onTap: () => onSelect(category.id!),
        ),
    ];
    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: choices);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final choice in choices)
            Padding(padding: const EdgeInsets.only(right: 8), child: choice),
        ],
      ),
    );
  }
}

/// Satu pilihan kategori: ikon berwarna dan namanya, bergaris saat dipilih.
class CategoryChoice extends StatelessWidget {
  const CategoryChoice({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('category-choice-${category.id}'),
        borderRadius: BorderRadius.circular(AppRadius.smallButton),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.paper2 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.smallButton),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              CategoryIconBox.category(
                iconKey: category.iconKey,
                color: CategoryStyle.color(category.colorValue),
              ),
              const SizedBox(height: 4),
              Text(
                category.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 10,
                  weight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.ink : AppColors.mut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
