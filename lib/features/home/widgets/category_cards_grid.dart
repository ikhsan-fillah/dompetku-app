import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../dashboard/models/dashboard_view_models.dart';

/// Kartu kategori dua kolom (favorit atau pengeluaran terbesar).
class CategoryCardsGrid extends StatelessWidget {
  const CategoryCardsGrid({super.key, required this.items, this.onTap});

  final List<CategoryCardData> items;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CategoryCard(item: items[i], onTap: onTap),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < items.length
                        ? _CategoryCard(item: items[i + 1], onTap: onTap)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item, this.onTap});

  final CategoryCardData item;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(item.colorValue);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap == null ? null : () => onTap!(item.categoryId),
      child: AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIconBox(
            icon: CategoryStyle.icon(item.iconKey),
            color: color,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatIdr(item.amount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            value: item.sharePercent / 100,
            height: 6,
            gradient: item.amount == 0
                ? const LinearGradient(
                    colors: [AppColors.track, AppColors.track],
                  )
                : LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
          ),
        ],
        ),
      ),
    );
  }
}
