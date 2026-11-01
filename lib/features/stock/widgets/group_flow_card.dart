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

/// Arah dana tiga kelompok: kalimat ringkas dan tiga kolom dari garis nol
/// (naik = net beli, turun = net jual, tingginya dibandingkan dengan kelompok
/// terbesar). Rincian beli dan jual per kelompok sengaja tidak ditampilkan
/// supaya kartu tetap ringkas.
class GroupFlowCard extends StatelessWidget {
  const GroupFlowCard({
    super.key,
    required this.summary,
    this.headline,
    this.contextLine,
    this.rangeLabel,
    this.others = const {},
  });

  final GroupSummary summary;

  /// Kalimat pembuka dari analisis lintas rentang. Null memakai kalimat
  /// sederhana dari tanda net tiap kelompok.
  final String? headline;

  /// Kalimat konteks harga dan rentang pembanding, null bila tidak ada.
  final String? contextLine;

  /// Rentang yang digambar sebagai batang, untuk catatan di bawah grafik.
  final String? rangeLabel;

  /// Net kelompok di rentang lain, ditampilkan sebagai angka kecil di bawah
  /// tiap kolom. Kunci = label rentang, urut tampil.
  final Map<String, GroupSummary> others;

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
            headline ?? flowHeadline(summary),
            style: AppText.display(size: 19, height: 1.25),
          ),
          if (contextLine case final String text) ...[
            const SizedBox(height: 6),
            Text(
              text,
              style: AppText.body(size: 12, color: AppColors.ink2, height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          ExcludeSemantics(
            child: _FlowChart(summary: summary, maxAbs: maxAbs, others: others),
          ),
          if (others.isNotEmpty && rangeLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              'Batang = @label. Angka kecil = rentang lain. ≈ berarti Stockbit hanya menampilkan angka bulat.'
                  .trParams({'label': rangeLabel!}),
              style: AppText.body(
                size: 10.5,
                color: AppColors.mut,
                height: 1.4,
              ),
            ),
          ],
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
  const _FlowChart({
    required this.summary,
    required this.maxAbs,
    this.others = const {},
  });

  final GroupSummary summary;
  final int maxAbs;
  final Map<String, GroupSummary> others;

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
                    if (others.isNotEmpty)
                      _OtherRanges(group: group, others: others),
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

/// Angka kecil per rentang lain di bawah satu kolom kelompok.
class _OtherRanges extends StatelessWidget {
  const _OtherRanges({required this.group, required this.others});

  final BrokerGroup group;
  final Map<String, GroupSummary> others;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 8, 6, 0),
      padding: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          for (final MapEntry(key: label, value: summary) in others.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    label,
                    style: AppText.body(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.mut,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Kolom kelompok sempit; angka panjang boleh turun baris
                  // daripada terpotong atau meluap.
                  Expanded(
                    child: Text(
                      summary.of(group).brokerCount == 0
                          ? '-'
                          : formatBrokerValue(
                              summary.of(group).netIdr,
                              approx: summary.of(group).hasApprox,
                            ),
                      textAlign: TextAlign.end,
                      style: AppText.mono(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: netColor(summary.of(group).netIdr),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
