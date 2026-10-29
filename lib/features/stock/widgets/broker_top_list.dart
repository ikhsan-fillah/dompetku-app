import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import 'stock_format.dart';

/// Daftar broker teratas di satu sisi: net beli atau net jual. Tiap baris
/// punya peringkat, kode broker, kelompoknya, nilai, dan batang yang
/// dibandingkan dengan broker terbesar di daftar yang sama.
class BrokerTopList extends StatelessWidget {
  const BrokerTopList({
    super.key,
    required this.side,
    required this.rows,
    required this.totalCount,
    required this.rules,
  });

  final BrokerSide side;

  /// Broker teratas sisi ini, terbesar dulu (sudah dipotong ke 5).
  final List<BrokerRangeRow> rows;

  /// Jumlah seluruh broker di sisi ini pada rentang yang sama.
  final int totalCount;

  final BrokerGroupRules rules;

  bool get _isBuy => side == BrokerSide.buy;

  @override
  Widget build(BuildContext context) {
    final color = _isBuy ? AppColors.earn : AppColors.spend;
    final soft = _isBuy ? AppColors.earnSoft : AppColors.spendSoft;
    final title = (_isBuy ? 'Top @count net beli' : 'Top @count net jual')
        .trParams({'count': '${rows.length}'});
    final sum = rows.fold<int>(0, (total, row) => total + row.signedValueIdr);
    final largest = rows.isEmpty ? 0 : rows.first.valueIdr;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _isBuy
                      ? LucideIcons.arrowUpRight
                      : LucideIcons.arrowDownRight,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.display(size: 16)),
                    Text(
                      'dari @total broker'.trParams({'total': '$totalCount'}),
                      style: AppText.body(size: 11, color: AppColors.mut),
                    ),
                  ],
                ),
              ),
              if (rows.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatBrokerValue(sum),
                      style: AppText.mono(
                        size: 14,
                        weight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      'jumlah'.tr,
                      style: AppText.body(size: 10.5, color: AppColors.mut),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                (_isBuy
                        ? 'Tidak ada broker net beli pada rentang ini.'
                        : 'Tidak ada broker net jual pada rentang ini.')
                    .tr,
                style: AppText.body(size: 12, color: AppColors.mut),
              ),
            )
          else
            for (final (index, row) in rows.indexed)
              _TopRow(
                rank: index + 1,
                row: row,
                group: rules.groupOf(row.brokerCode),
                fraction: largest == 0 ? 0 : row.valueIdr / largest,
                color: color,
                soft: soft,
                isLast: index == rows.length - 1,
              ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.rank,
    required this.row,
    required this.group,
    required this.fraction,
    required this.color,
    required this.soft,
    required this.isLast,
  });

  final int rank;
  final BrokerRangeRow row;
  final BrokerGroup? group;
  final double fraction;
  final Color color;
  final Color soft;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final groupText = switch (group) {
      final BrokerGroup known => known.label.tr,
      null => 'belum diklasifikasi'.tr,
    };
    final valueText = formatBrokerValue(
      row.signedValueIdr,
      approx: row.isApprox,
    );
    return Semantics(
      container: true,
      label: '$rank. ${row.brokerCode}, $groupText, $valueText',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 9, 0, isLast ? 12 : 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$rank',
                      style: AppText.mono(size: 12, color: AppColors.mut),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      row.brokerCode,
                      style: AppText.mono(size: 15, weight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          groupText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 10,
                            weight: FontWeight.w600,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    valueText,
                    style: AppText.mono(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: AppColors.line2),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction.clamp(0.0, 1.0),
                          child: ColoredBox(
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
