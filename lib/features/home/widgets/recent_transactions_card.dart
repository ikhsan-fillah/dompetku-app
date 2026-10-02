import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
              if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CategoryIconBox(
            icon: income
                ? Icons.south_west_rounded
                : CategoryStyle.icon(item.iconKey),
            color: income
                ? AppColors.income
                : CategoryStyle.color(item.colorValue),
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.categoryName} · ${DateLabel.day(item.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${income ? '+' : '−'} ${formatIdr(item.amount)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: income ? AppColors.income : AppColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}
