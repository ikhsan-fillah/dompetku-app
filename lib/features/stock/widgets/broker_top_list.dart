import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../services/broker_group_calculator.dart';
import '../services/broker_flow_analysis.dart';
import 'broker_insights.dart';
import 'stock_format.dart';

/// Daftar broker teratas di satu sisi: net beli atau net jual. Dibuat
/// ramping supaya dua daftar muat bersampingan di layar HP. Kepala kartu
/// berisi jumlah dan banyaknya broker; tiap baris punya peringkat, kode,
/// nilai, batang yang dibandingkan dengan broker terbesar, dan kelompoknya.
class BrokerTopList extends StatelessWidget {
  const BrokerTopList({
    super.key,
    required this.side,
    required this.rows,
    required this.totalCount,
    required this.rules,
    this.trails = const {},
    this.topShare,
  });

  final BrokerSide side;

  /// Broker teratas sisi ini, terbesar dulu (sudah dipotong ke 5).
  final List<BrokerRangeRow> rows;

  /// Jumlah seluruh broker di sisi ini pada rentang yang sama.
  final int totalCount;

  final BrokerGroupRules rules;

  /// Jejak tiap broker di keempat rentang, kunci kode broker.
  final Map<String, BrokerTrail> trails;

  /// Porsi tiga broker teratas terhadap total sisi ini, 0 sampai 1.
  final double? topShare;

  bool get _isBuy => side == BrokerSide.buy;

  @override
  Widget build(BuildContext context) {
    final color = _isBuy ? AppColors.earn : AppColors.spend;
    final soft = _isBuy ? AppColors.earnSoft : AppColors.spendSoft;
    final sum = rows.fold<int>(0, (total, row) => total + row.signedValueIdr);
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isBuy
                      ? LucideIcons.arrowUpRight
                      : LucideIcons.arrowDownRight,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (_isBuy ? 'Net beli' : 'Net jual').tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rows.isEmpty ? '-' : formatBrokerValue(sum),
            style: AppText.mono(
              size: 15,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            topShare == null
                ? 'jumlah @total broker · top @count'.trParams({
                    'total': '$totalCount',
                    'count': '${rows.length}',
                  })
                : '@total broker · 3 teratas = @share%'.trParams({
                    'total': '$totalCount',
                    'share': '${(topShare! * 100).round()}',
                  }),
            style: AppText.body(size: 10.5, color: AppColors.mut),
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
                trail: trails[row.brokerCode],
                color: color,
                isFirst: index == 0,
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
    required this.trail,
    required this.color,
    required this.isFirst,
  });

  final int rank;
  final BrokerRangeRow row;
  final BrokerGroup? group;
  final BrokerTrail? trail;
  final Color color;
  final bool isFirst;

  /// Bandar di luar [bandarTopCount] teratas tidak ikut dihitung di bar
  /// kelompok, jadi labelnya dibuat pudar supaya terlihat beda.
  bool get _outsideBandarTop =>
      group == BrokerGroup.bandar && rank > bandarTopCount;

  /// Warna label kelompok: biru asing, kuning bandar, ungu ritel.
  static (Color, Color) _groupColors(BrokerGroup? group) => switch (group) {
    BrokerGroup.asing => (const Color(0xFFE4ECF4), const Color(0xFF2F5D8A)),
    BrokerGroup.bandar => (AppColors.warnSoft, AppColors.warn),
    BrokerGroup.ritel => (const Color(0xFFEDE3F1), const Color(0xFF6E4C82)),
    null => (AppColors.paper2, AppColors.ink2),
  };

  @override
  Widget build(BuildContext context) {
    final groupText = switch (group) {
      final BrokerGroup known => known.label.tr.toLowerCase(),
      null => 'lainnya'.tr,
    };
    final valueText = formatBrokerValue(
      row.signedValueIdr,
      approx: row.isApprox,
    );
    final (solidBg, solidFg) = _groupColors(group);
    final groupBg = _outsideBandarTop
        ? solidBg.withValues(alpha: 0.4)
        : solidBg;
    final groupFg = _outsideBandarTop
        ? solidFg.withValues(alpha: 0.55)
        : solidFg;
    final same = trail?.sameAs(row.side == BrokerSide.buy ? 1 : -1);
    return Semantics(
      container: true,
      label: [
        '$rank. ${row.brokerCode}, $groupText'
            '${_outsideBandarTop ? ', tidak dihitung di bar' : ''}, $valueText',
        if (same != null)
          '@count dari 4 rentang searah'.trParams({'count': '$same'}),
      ].join(', '),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isFirst
                ? null
                : const Border(top: BorderSide(color: AppColors.line2)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      row.brokerCode,
                      style: AppText.mono(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: groupBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        groupText,
                        style: AppText.body(
                          size: 9.5,
                          weight: FontWeight.w700,
                          color: groupFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        valueText,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: AppText.mono(
                          size: 12,
                          weight: FontWeight.w600,
                          color: color,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                if (trail case final BrokerTrail t) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TrailDots(values: t.values),
                      const Spacer(),
                      Text(
                        '$same/4',
                        style: AppText.body(
                          size: 9.5,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
