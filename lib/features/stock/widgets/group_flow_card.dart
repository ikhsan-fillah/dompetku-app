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

/// Menggabungkan nama: "Ritel", "Ritel dan Bandar", "Ritel, Bandar dan Asing".
String _joinNames(List<String> names) => switch (names) {
  [] => '',
  [final only] => only,
  [final first, final second] => '$first ${'dan'.tr} $second',
  [...final init, final last] => '${init.join(', ')} ${'dan'.tr} $last',
};

/// Kalimat pembuka kartu kelompok, dari tanda net tiap kelompok saja.
/// Kelompok yang netnya nol atau tidak tampil tidak disebut.
String flowHeadline(GroupSummary summary) {
  final buyers = <String>[];
  final sellers = <String>[];
  for (final group in BrokerGroup.values) {
    final net = summary.of(group).netIdr;
    if (net > 0) buyers.add(group.label.tr);
    if (net < 0) sellers.add(group.label.tr);
  }
  return switch ((buyers, sellers)) {
    ([], []) => 'Tidak ada arus bersih pada rentang ini.'.tr,
    (final b, []) => '@names net beli.'.trParams({'names': _joinNames(b)}),
    ([], final s) => '@names net jual.'.trParams({'names': _joinNames(s)}),
    (final b, final s) => '@buy net beli, @sell net jual.'.trParams({
      'buy': _joinNames(b),
      'sell': _joinNames(s),
    }),
  };
}

/// Arah dana tiga kelompok. Bagian atas: kalimat ringkas dan tiga kolom dari
/// garis nol (naik = net beli, turun = net jual, tingginya dibandingkan
/// dengan kelompok terbesar). Bagian bawah: komposisi beli dan jual tiap
/// kelompok, supaya terlihat dana yang berputar, bukan hanya selisihnya.
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Arah dana per kelompok'.tr,
            style: AppText.label(color: AppColors.mut, size: 11),
          ),
          const SizedBox(height: 8),
          Text(
            flowHeadline(summary),
            style: AppText.display(size: 19, height: 1.25),
          ),
          const SizedBox(height: 18),
          ExcludeSemantics(
            child: _FlowChart(summary: summary, maxAbs: maxAbs),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line2),
          for (final group in BrokerGroup.values)
            _CompositionRow(group: group, total: summary.of(group)),
          if (unclassified.brokerCount > 0) ...[
            const Divider(height: 24, color: AppColors.line2),
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

/// Tiga kolom dari garis nol bersama.
class _FlowChart extends StatelessWidget {
  const _FlowChart({required this.summary, required this.maxAbs});

  final GroupSummary summary;
  final int maxAbs;

  static const _half = 88.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final group in BrokerGroup.values)
              Expanded(
                child: _Half(
                  up: true,
                  total: summary.of(group),
                  maxAbs: maxAbs,
                  height: _half,
                ),
              ),
          ],
        ),
        Container(height: 2, color: AppColors.ink2),
        Row(
          children: [
            for (final group in BrokerGroup.values)
              Expanded(
                child: _Half(
                  up: false,
                  total: summary.of(group),
                  maxAbs: maxAbs,
                  height: _half,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final group in BrokerGroup.values)
              Expanded(
                child: Column(
                  children: [
                    Text(group.label.tr, style: AppText.display(size: 15)),
                    Text(
                      '@count broker'.trParams({
                        'count': '${summary.of(group).brokerCount}',
                      }),
                      style: AppText.body(size: 10.5, color: AppColors.mut),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Setengah kolom di atas atau di bawah garis nol. Batang dan angkanya hanya
/// muncul di sisi yang sesuai tanda net kelompok.
class _Half extends StatelessWidget {
  const _Half({
    required this.up,
    required this.total,
    required this.maxAbs,
    required this.height,
  });

  final bool up;
  final GroupTotal total;
  final int maxAbs;
  final double height;

  static const _labelRoom = 24.0;
  static const _barWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    final net = total.netIdr;
    final empty = total.brokerCount == 0;
    final onThisSide = up ? net >= 0 : net < 0;
    if (!onThisSide) return SizedBox(height: height);

    final fraction = maxAbs == 0 ? 0.0 : (net.abs() / maxAbs).clamp(0.0, 1.0);
    final target = net == 0 || empty
        ? 0.0
        : math.max(4.0, fraction * (height - _labelRoom));
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final color = net < 0 ? AppColors.spend : AppColors.earn;
    final label = Text(
      empty ? '-' : formatBrokerValue(net, approx: total.hasApprox),
      style: AppText.mono(
        size: 12.5,
        weight: FontWeight.w600,
        color: empty ? AppColors.mut : netColor(net),
        letterSpacing: -0.3,
      ),
    );
    const radius = Radius.circular(7);
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, barHeight, _) {
          final bar = Container(
            width: _barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(
                top: up ? radius : Radius.zero,
                bottom: up ? Radius.zero : radius,
              ),
            ),
          );
          return Column(
            mainAxisAlignment: up
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: up
                ? [label, const SizedBox(height: 4), bar]
                : [bar, const SizedBox(height: 4), label],
          );
        },
      ),
    );
  }
}

/// Satu kelompok: net, lalu batang komposisi beli (hijau) dan jual (merah).
class _CompositionRow extends StatelessWidget {
  const _CompositionRow({required this.group, required this.total});

  final BrokerGroup group;
  final GroupTotal total;

  @override
  Widget build(BuildContext context) {
    final empty = total.brokerCount == 0;
    final net = total.netIdr;
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
                      style: AppText.display(size: 15),
                    ),
                  ),
                  Text(
                    netText,
                    style: AppText.mono(
                      size: 14,
                      weight: FontWeight.w600,
                      color: empty ? AppColors.mut : netColor(net),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SplitBar(
                buy: empty ? 0 : total.buyIdr,
                sell: empty ? 0 : total.sellIdr,
              ),
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

/// Batang komposisi: porsi beli (hijau) dan jual (merah) dari seluruh dana
/// yang berputar. Kosong (abu-abu) bila tidak ada transaksi.
class SplitBar extends StatelessWidget {
  const SplitBar({
    super.key,
    required this.buy,
    required this.sell,
    this.height = 8,
  });

  final int buy;
  final int sell;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = buy + sell;
    final radius = BorderRadius.circular(height / 2);
    if (total <= 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(color: AppColors.line2, borderRadius: radius),
      );
    }
    // Flex bulat; sisi yang ada tidak boleh hilang walau porsinya kecil.
    final buyFlex = buy == 0 ? 0 : math.max(1, (buy / total * 1000).round());
    final sellFlex = sell == 0 ? 0 : math.max(1, (sell / total * 1000).round());
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (buyFlex > 0)
              Expanded(
                flex: buyFlex,
                child: const ColoredBox(color: AppColors.earn),
              ),
            if (buyFlex > 0 && sellFlex > 0) const SizedBox(width: 2),
            if (sellFlex > 0)
              Expanded(
                flex: sellFlex,
                child: const ColoredBox(color: AppColors.spend),
              ),
          ],
        ),
      ),
    );
  }
}

/// Batang dua arah dari garis tengah: net beli ke kanan, net jual ke kiri,
/// panjangnya dibandingkan dengan [maxAbs]. Dipakai di kartu watchlist.
class FlowBar extends StatelessWidget {
  const FlowBar({
    super.key,
    required this.net,
    required this.maxAbs,
    this.height = 8,
  });

  final int net;
  final int maxAbs;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fraction = maxAbs == 0 ? 0.0 : (net.abs() / maxAbs).clamp(0.0, 1.0);
    final radius = Radius.circular(height / 2);
    return SizedBox(
      height: height + 4,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: net < 0 ? fraction : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.spend,
                    borderRadius: BorderRadius.horizontal(left: radius),
                  ),
                  child: SizedBox(height: height),
                ),
              ),
            ),
          ),
          Container(width: 2, height: height + 4, color: AppColors.ink2),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: net > 0 ? fraction : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.earn,
                    borderRadius: BorderRadius.horizontal(right: radius),
                  ),
                  child: SizedBox(height: height),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
