import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/formatter.dart';
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
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 47, bottom: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ActionButton(
                        label: 'Edit'.tr,
                        icon: LucideIcons.pencil,
                        background: AppColors.paper2,
                        foreground: AppColors.ink,
                        onTap: onEdit,
                      ),
                      _ActionButton(
                        label: 'Duplikat'.tr,
                        icon: LucideIcons.copy,
                        background: AppColors.paper2,
                        foreground: AppColors.ink,
                        onTap: onDuplicate,
                      ),
                      _ActionButton(
                        label: 'Hapus'.tr,
                        icon: LucideIcons.trash2,
                        background: AppColors.spendSoft,
                        foreground: AppColors.spend,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13, color: foreground),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        minimumSize: const Size(48, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        textStyle: AppText.body(size: 11, weight: FontWeight.w700),
      ),
    );
  }
}
