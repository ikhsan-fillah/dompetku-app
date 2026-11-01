import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/price_point.dart';
import '../services/broker_flow_analysis.dart';
import 'group_flow_card.dart';
import 'stock_format.dart';

/// Rentang dalam kalimat: "hari itu", "seminggu", "sebulan", "tiga bulan".
String periodPhrase(String label) => switch (label) {
  'Latest' => 'hari itu'.tr,
  '7D' => 'seminggu'.tr,
  '1M' => 'sebulan'.tr,
  '3M' => 'tiga bulan'.tr,
  _ => label,
};

/// Kalimat pembuka kartu kelompok, mis. "Asing masuk hari itu, setelah
/// sebulan keluar." Masuk = net beli, keluar = net jual.
String headlineText(FlowHeadline h) {
  final buy = h.selectedNet > 0;
  if (h.compareNet == 0) {
    return (buy ? '@group masuk @period.' : '@group keluar @period.').trParams({
      'group': h.group.label.tr,
      'period': periodPhrase(h.selectedLabel),
    });
  }
  final key = switch ((buy, h.reversed)) {
    (true, true) => '@group masuk @period, setelah @compare keluar.',
    (false, true) => '@group keluar @period, setelah @compare masuk.',
    (true, false) => '@group masuk @period, searah dengan @compare terakhir.',
    (false, false) => '@group keluar @period, searah dengan @compare terakhir.',
  };
  return key.trParams({
    'group': h.group.label.tr,
    'period': periodPhrase(h.selectedLabel),
    'compare': periodPhrase(h.compareLabel),
  });
}

/// Kalimat konteks: perubahan harga pada rentang terpilih, lalu net kelompok
/// utama di rentang pembanding. Null bila harga rentang itu tidak ada.
String? contextText({
  required FlowHeadline headline,
  required DateTime rangeStart,
  required DateTime rangeEnd,
  required List<PricePoint> history,
}) {
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final endIndex = history.lastIndexWhere(
    (p) => !day(p.date).isAfter(day(rangeEnd)),
  );
  final startIndex = history.lastIndexWhere(
    (p) => day(p.date).isBefore(day(rangeStart)),
  );
  final parts = <String>[];
  if (endIndex >= 0 && startIndex >= 0 && startIndex < endIndex) {
    final from = history[startIndex].close;
    final to = history[endIndex].close;
    final args = {
      'change': formatPercent((to / from - 1) * 100),
      'from': formatPrice(from.round()),
      'to': formatPrice(to.round()),
    };
    parts.add(
      rangeStart == rangeEnd
          ? 'Pada @date harga @change (@from ke @to).'.trParams({
              ...args,
              'date': formatDayMonth(rangeEnd),
            })
          : 'Selama rentang ini harga @change (@from ke @to).'.trParams(args),
    );
  }
  if (headline.compareNet != 0) {
    parts.add(
      'Dalam @compare, @group net @value.'.trParams({
        'compare': periodPhrase(headline.compareLabel),
        'group': headline.group.label.tr,
        'value': formatBrokerValue(
          headline.compareNet,
          approx: headline.compareApprox,
        ),
      }),
    );
  }
  return parts.isEmpty ? null : parts.join(' ');
}

String _groupName(BrokerGroup? group) =>
    (group?.label.tr ?? 'lainnya'.tr).toLowerCase();

String _joinList(List<String> items) => switch (items) {
  [] => '',
  [final only] => only,
  [...final init, final last] => '${init.join(', ')} ${'dan'.tr} $last',
};

/// Satu fakta di kartu "Yang menonjol".
class _Fact {
  const _Fact(this.icon, this.color, this.soft, this.title, this.body);

  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String body;
}

/// Kartu "Yang menonjol": broker yang searah di keempat rentang, porsi tiga
/// broker teratas, dan penjual terbesar tiga bulan. Fakta yang datanya tidak
/// ada tidak ditampilkan. Semuanya deskripsi aliran dana, bukan prediksi.
class BrokerHighlightsCard extends StatelessWidget {
  const BrokerHighlightsCard({
    super.key,
    required this.analysis,
    required this.selected,
  });

  final BrokerFlowAnalysis analysis;
  final String selected;

  List<_Fact> _facts() {
    final facts = <_Fact>[];
    String named(BrokerTrail t) => '${t.code} (${_groupName(t.group)})';

    final buyers = analysis.consistent(1).take(4).toList();
    if (buyers.isNotEmpty) {
      facts.add(
        _Fact(
          LucideIcons.repeat,
          AppColors.earn,
          AppColors.earnSoft,
          'Beli di keempat rentang'.tr,
          '@list selalu di sisi net beli: Latest, 7D, 1M, dan 3M.'.trParams({
            'list': _joinList([for (final t in buyers) named(t)]),
          }),
        ),
      );
    }
    final sellers = analysis.consistent(-1).take(4).toList();
    if (sellers.isNotEmpty) {
      facts.add(
        _Fact(
          LucideIcons.repeat,
          AppColors.spend,
          AppColors.spendSoft,
          'Jual di keempat rentang'.tr,
          '@list selalu di sisi net jual: Latest, 7D, 1M, dan 3M.'.trParams({
            'list': _joinList([for (final t in sellers) named(t)]),
          }),
        ),
      );
    }
    final buyShare = analysis.topShare(selected, BrokerSide.buy);
    final sellShare = analysis.topShare(selected, BrokerSide.sell);
    if (buyShare != null && sellShare != null) {
      facts.add(
        _Fact(
          LucideIcons.target,
          AppColors.ink2,
          AppColors.paper2,
          'Porsi 3 broker teratas'.tr,
          '3 broker teratas = @buy% dari total net beli @label, dan @sell% dari total net jual.'
              .trParams({
                'buy': '${(buyShare * 100).round()}',
                'sell': '${(sellShare * 100).round()}',
                'label': selected,
              }),
        ),
      );
    }
    final big = analysis.largest('3M', BrokerSide.sell);
    if (big.isNotEmpty) {
      final list = _joinList([
        for (final b in big)
          '${b.code} ${formatBrokerValue(b.value, approx: b.approx)}',
      ]);
      final groups = {for (final b in big) b.group};
      var body = groups.length == 1 && groups.first != null
          ? '@list. Semuanya @group.'.trParams({
              'list': list,
              'group': _groupName(groups.first),
            })
          : '$list.';
      if (selected != '3M') {
        for (final b in big) {
          final now = analysis.netOf(selected, b.code);
          if (now != null && now > 0) {
            body +=
                ' ${'@code justru net beli @value pada @label.'.trParams({'code': b.code, 'value': formatBrokerValue(now, approx: analysis.approxOf(selected, b.code)), 'label': selected})}';
            break;
          }
        }
      }
      facts.add(
        _Fact(
          LucideIcons.arrowDownRight,
          AppColors.spend,
          AppColors.spendSoft,
          'Penjual terbesar 3M'.tr,
          body,
        ),
      );
    }
    return facts;
  }

  @override
  Widget build(BuildContext context) {
    final facts = _facts();
    if (facts.isEmpty) return const SizedBox.shrink();
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Yang menonjol'.tr.toUpperCase(),
            style: AppText.label(color: AppColors.mut, size: 11),
          ),
          const SizedBox(height: 4),
          for (final (index, fact) in facts.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : const Border(top: BorderSide(color: AppColors.line2)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: fact.soft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(fact.icon, size: 16, color: fact.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fact.title,
                            style: AppText.body(
                              size: 13,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fact.body,
                            style: AppText.body(
                              size: 12,
                              color: AppColors.ink2,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Empat kotak kecil untuk Latest, 7D, 1M, 3M: hijau net beli, merah net
/// jual, kosong bila broker tidak tampil di rentang itu.
class TrailDots extends StatelessWidget {
  const TrailDots({super.key, required this.values});

  final List<int?> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, value) in values.indexed) ...[
          if (index > 0) const SizedBox(width: 3),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: value == null ? null : netColor(value),
              border: value == null ? Border.all(color: AppColors.line) : null,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Legenda jejak di atas daftar broker teratas.
class TrailLegend extends StatelessWidget {
  const TrailLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: TrailDots(values: [1, -1, null]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Jejak: Latest · 7D · 1M · 3M. Kosong = tidak tampil di daftar. 4/4 = searah di semua rentang.'
                .tr,
            style: AppText.body(size: 10.5, color: AppColors.mut, height: 1.4),
          ),
        ),
      ],
    );
  }
}
