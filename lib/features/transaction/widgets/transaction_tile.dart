import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/card_actions.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../dashboard/models/dashboard_view_models.dart';

/// Satu baris transaksi. Bila [expanded], tampil aksi Edit, Duplikat, dan Hapus.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    required this.expanded,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final RecentTransactionItem item;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final income = item.isIncome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.smallButton),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                CategoryIconBox(
                  icon: income
                      ? LucideIcons.arrowDownLeft
                      : CategoryStyle.icon(item.iconKey),
                  color: income
                      ? AppColors.earn
                      : CategoryStyle.color(item.colorValue),
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
        ),
        CardActionBar(
          expanded: expanded,
          padding: const EdgeInsets.only(left: 47, bottom: 10),
          actions: [
            CardAction(
              label: 'Edit'.tr,
              icon: LucideIcons.pencil,
              onTap: onEdit,
            ),
            CardAction(
              label: 'Duplikat'.tr,
              icon: LucideIcons.copy,
              onTap: onDuplicate,
            ),
            CardAction(
              label: 'Hapus'.tr,
              icon: LucideIcons.trash2,
              onTap: onDelete,
              danger: true,
            ),
          ],
        ),
      ],
    );
  }
}
