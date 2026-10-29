import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../models/broker_group.dart';
import '../services/broker_group_calculator.dart';
import 'stock_format.dart';

/// Warna angka net: hijau untuk net beli, merah untuk net jual.
Color netColor(int net) => switch (net) {
  > 0 => AppColors.earn,
  < 0 => AppColors.spend,
  _ => AppColors.ink2,
};

/// Arah dana tiga kelompok dalam satu kartu. Tiap kelompok punya batang dua
/// arah dari garis tengah: ke kanan net beli, ke kiri net jual, panjangnya
/// dibandingkan dengan kelompok yang terbesar pada rentang yang sama.
class GroupFlowCard extends StatelessWidget {
  const GroupFlowCard({super.key, required this.summary});

  final GroupSummary summary;

  @override
  Widget build(BuildContext context) {
    final maxAbs = BrokerGroup.values
        .map((group) => summary.of(group).netIdr.abs())
        .fold(0, math.max);
    final unclassified = summary.unclassified;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Arah dana per kelompok'.tr,
            style: AppText.label(color: AppColors.mut, size: 11),
          ),
          for (final group in BrokerGroup.values)
            _GroupRow(group: group, total: summary.of(group), maxAbs: maxAbs),
          if (unclassified.brokerCount > 0) ...[
            const Divider(height: 22, color: AppColors.line2),
            Text(
              'Belum diklasifikasi: @count broker, net @net (tidak masuk kelompok mana pun)'
                  .trParams({
                    'count': '${unclassified.brokerCount}',
                    'net': formatBrokerValue(unclassified.netIdr),
                  }),
              style: AppText.body(size: 11, color: AppColors.mut, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.total,
    required this.maxAbs,
  });

  final BrokerGroup group;
  final GroupTotal total;
  final int maxAbs;

  @override
  Widget build(BuildContext context) {
    final net = total.netIdr;
    final empty = total.brokerCount == 0;
    final netText = empty
        ? '-'
        : formatBrokerValue(net, approx: total.hasApprox);
    final caption = empty
        ? 'Tidak ada broker kelompok ini yang tampil'.tr
        : 'beli @buy · jual @sell · @count broker'.trParams({
            'buy': formatBrokerValue(
              total.buyIdr,
              signed: false,
              approx: total.hasApprox,
            ),
            'sell': formatBrokerValue(
              total.sellIdr,
              signed: false,
              approx: total.hasApprox,
            ),
            'count': '${total.brokerCount}',
          });
    return Semantics(
      container: true,
      label: '${group.label.tr}, net $netText. $caption',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.label.tr,
                      style: AppText.display(size: 16),
                    ),
                  ),
                  Text(
                    netText,
                    style: AppText.mono(
                      size: 15,
                      weight: FontWeight.w600,
                      color: empty ? AppColors.mut : netColor(net),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FlowBar(net: empty ? 0 : net, maxAbs: maxAbs),
              const SizedBox(height: 6),
              Text(
                caption,
                style: AppText.body(size: 11, color: AppColors.mut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Batang dua arah: garis tengah, net beli ke kanan, net jual ke kiri.
class _FlowBar extends StatelessWidget {
  const _FlowBar({required this.net, required this.maxAbs});

  final int net;
  final int maxAbs;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAbs == 0 ? 0.0 : (net.abs() / maxAbs).clamp(0.0, 1.0);
    const radius = Radius.circular(5);
    return SizedBox(
      height: 10,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: net < 0 ? fraction : 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.spend,
                    borderRadius: BorderRadius.horizontal(left: radius),
                  ),
                  child: SizedBox(height: 10),
                ),
              ),
            ),
          ),
          Container(width: 2, height: 14, color: AppColors.ink2),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: net > 0 ? fraction : 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.earn,
                    borderRadius: BorderRadius.horizontal(right: radius),
                  ),
                  child: SizedBox(height: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
