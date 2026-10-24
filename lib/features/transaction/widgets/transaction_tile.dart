import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../dashboard/models/dashboard_view_models.dart';

/// Satu baris transaksi. Ketuk untuk Edit; Hapus lewat geser kartu.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item, required this.onTap});

  final RecentTransactionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final income = item.isIncome;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.smallButton),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            income
                ? const CategoryIconBox(
                    icon: LucideIcons.arrowDownLeft,
                    color: AppColors.earn,
                  )
                : CategoryIconBox.category(
                    iconKey: item.iconKey,
                    color: CategoryStyle.color(item.colorValue),
                  ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 13, weight: FontWeight.w700),
                  ),
                  Text(
                    item.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 10.5, color: AppColors.mut),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${income ? '+' : '\u2212'} ${formatIdr(item.amount)}',
              style: AppText.mono(
                size: 12.5,
                weight: FontWeight.w500,
                color: income ? AppColors.earn : AppColors.spend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
