import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../../core/widgets/section_header.dart';
import '../../dashboard/models/dashboard_view_models.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
    required this.items,
    required this.onSeeAll,
  });

  final List<RecentTransactionItem> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Transaksi terbaru',
            actionLabel: items.isEmpty ? null : 'Lihat semua',
            onAction: items.isEmpty ? null : onSeeAll,
          ),
          if (items.isNotEmpty)
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.line2),
              _Row(item: items[i]),
            ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final RecentTransactionItem item;

  @override
  Widget build(BuildContext context) {
    final income = item.isIncome;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          CategoryIconBox(
            icon: income
                ? LucideIcons.arrowDown
                : CategoryStyle.icon(item.iconKey),
            color: income
                ? AppColors.earn
                : CategoryStyle.color(item.colorValue),
            size: 36,
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
                  '${item.categoryName} · ${DateLabel.day(item.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 10.5, color: AppColors.mut),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${income ? '+' : '−'} ${formatIdr(item.amount)}',
            style: AppText.mono(
              size: 12.5,
              color: income ? AppColors.earn : AppColors.spend,
            ),
          ),
        ],
      ),
    );
  }
}
