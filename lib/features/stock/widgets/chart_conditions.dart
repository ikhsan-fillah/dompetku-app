import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../models/daily_bar.dart';
import '../models/news_score.dart';
import '../models/price_point.dart';
import '../services/price_analysis.dart';
import '../services/technical_scan.dart';
import 'stock_format.dart';
import 'technical_section.dart';
import 'trend_pill.dart';

/// Garis rata-rata, pita Bollinger, dan zona support/resistance untuk hari
/// yang digambar. Null bila riwayat terlalu pendek.
PriceOverlay? buildOverlay(List<PricePoint> history, List<DailyBar> bars) {
  if (history.length < 60 || bars.isEmpty) return null;
  return PriceOverlay(
    ma20: alignedSma(history, bars, 20),
    ma50: alignedSma(history, bars, 50),
    bbLower: alignedBollingerLower(history, bars),
    zones: findSupportResistance(history),
    ma200: alignedSma(history, bars, 200),
    rsi: alignedRsi(history, bars),
    divergence: findLowDivergence(history),
  );
}

String _candleName(CandlePattern p) => switch (p) {
  CandlePattern.hammer => 'Hammer',
  CandlePattern.bullishEngulfing => 'Bullish engulfing',
  CandlePattern.piercing => 'Piercing line',
  CandlePattern.morningStar => 'Morning star',
  CandlePattern.bullishHarami => 'Bullish harami',
  CandlePattern.shootingStar => 'Shooting star',
  CandlePattern.bearishEngulfing => 'Bearish engulfing',
  CandlePattern.darkCloud => 'Dark cloud cover',
  CandlePattern.eveningStar => 'Evening star',
  CandlePattern.bearishHarami => 'Bearish harami',
};

String _patternName(ChartPatternKind k) => switch (k) {
  ChartPatternKind.doubleBottom => 'Double bottom'.tr,
  ChartPatternKind.doubleTop => 'Double top'.tr,
  ChartPatternKind.headShoulders => 'Head and shoulders'.tr,
  ChartPatternKind.inverseHeadShoulders => 'Inverse head and shoulders'.tr,
  ChartPatternKind.ascendingUp => 'Segitiga naik, tembus atas'.tr,
  ChartPatternKind.ascendingDown => 'Segitiga naik, tembus bawah'.tr,
  ChartPatternKind.descendingUp => 'Segitiga turun, tembus atas'.tr,
  ChartPatternKind.descendingDown => 'Segitiga turun, tembus bawah'.tr,
  ChartPatternKind.symmetricUp => 'Segitiga simetris, tembus atas'.tr,
  ChartPatternKind.symmetricDown => 'Segitiga simetris, tembus bawah'.tr,
  ChartPatternKind.bullFlag => 'Flag bullish'.tr,
  ChartPatternKind.bearFlag => 'Flag bearish'.tr,
};

/// Berapa hari bursa terakhir yang dicek untuk pola chart.
const chartPatternRecentBars = 10;

/// Fakta singkat di bawah chart harga: posisi di rentang 60 hari,
/// candlestick, divergence, pola chart, dan skenario katalog. Semuanya
/// otomatis dan deskriptif, bukan sinyal.
List<ChartFact> chartFacts(List<PricePoint> history) {
  final facts = <ChartFact>[];
  final range = rangePosition(history);
  if (range != null) {
    facts.add(
      ChartFact(
        'Posisi'.tr,
        '@pct% dari bawah rentang 60 hari (@low sampai @high)'.trParams({
          'pct': '${(range.fraction * 100).round()}',
          'low': formatPrice(range.low.round()),
          'high': formatPrice(range.high.round()),
        }),
      ),
    );
  }
  if (history.length < 60) return facts;
  final scan = TechnicalScan(history);
  final lastDate = formatDayMonth(history.last.date);
  final candles = scan.candles();
  facts.add(
    ChartFact(
      'Candlestick'.tr,
      candles.isEmpty
          ? 'tidak ada pola pada @date'.trParams({'date': lastDate})
          : '@list pada @date'.trParams({
              'list': candles.map(_candleName).join(', '),
              'date': lastDate,
            }),
    ),
  );
  final div = findLowDivergence(history);
  facts.add(
    ChartFact(
      'Divergence RSI?'.tr,
      div == null
          ? 'tidak terdeteksi dalam 20 hari'.tr
          : 'harga buat titik terendah baru (@p2, @d2), RSI tidak (@r2 vs @r1 pada @d1). Kasar, sering palsu.'
                .trParams({
                  'p2': formatPrice(div.secondPrice.round()),
                  'd2': formatDayMonth(div.secondDate),
                  'r2': formatIndicator(div.secondRsi, digits: 1),
                  'r1': formatIndicator(div.firstRsi, digits: 1),
                  'd1': formatDayMonth(div.firstDate),
                }),
    ),
  );
  final pattern = scan.latestChartPattern(recentBars: chartPatternRecentBars);
  facts.add(
    ChartFact(
      'Pola chart'.tr,
      pattern == null
          ? 'tidak ada dalam @n hari bursa terakhir'.trParams({
              'n': '$chartPatternRecentBars',
            })
          : 'menyerupai @name, tembus @date (titik kunci @keys)'.trParams({
              'name': _patternName(pattern.kind),
              'date': formatDayMonth(pattern.breakout),
              'keys': pattern.keyDates.map(formatDayMonth).join(', '),
            }),
      warn: true,
    ),
  );
  final checks = scan.scenarios();
  if (checks.isNotEmpty) {
    final active = [
      for (final c in checks)
        if (c.active) c.code,
    ];
    final partial = [
      for (final c in checks)
        if (!c.active) '${c.code} ${c.met}/${c.total}',
    ].join(', ');
    facts.add(
      ChartFact(
        'Skenario katalog'.tr,
        active.isEmpty
            ? 'tidak ada yang aktif (@list syarat)'.trParams({'list': partial})
            : '@codes aktif (hasil uji lemah, bukan sinyal)'.trParams({
                'codes': active.join(', '),
              }),
      ),
    );
  }
  return facts;
}

/// "di bawah MA50, MA200" dan variasinya.
String _maPosition(TrendFacts t) {
  final below50 = t.close < t.ma50;
  final below200 = t.close < t.ma200;
  if (below50 && below200) return 'di bawah MA50, MA200'.tr;
  if (!below50 && !below200) return 'di atas MA50, MA200'.tr;
  return below50
      ? 'di bawah MA50, di atas MA200'.tr
      : 'di atas MA50, di bawah MA200'.tr;
}

/// Empat ubin ringkas di atas chart: tren, sentimen pasar (IHSG), support,
/// dan resistance. Ubin yang datanya tidak ada menampilkan tanda strip.
class ChartConditionStrip extends StatelessWidget {
  const ChartConditionStrip({
    super.key,
    required this.history,
    required this.market,
    this.news,
  });

  final List<PricePoint> history;
  final List<PricePoint> market;
  final NewsScore? news;

  @override
  Widget build(BuildContext context) {
    final trend = trendFacts(history);
    final mood = marketSentiment(market);
    final zones = findSupportResistance(history);
    final trendColor = trend == null
        ? AppColors.ink2
        : trendStyle(trend.kind).$3;
    final trendLabel = switch (trend?.kind) {
      TrendKind.naik => 'Naik'.tr,
      TrendKind.turun => 'Turun'.tr,
      TrendKind.campuran => 'Campuran'.tr,
      null => '-',
    };
    final moodText = switch (mood?.mood) {
      MarketMood.kuat => 'Kuat'.tr,
      MarketMood.netral => 'Netral'.tr,
      MarketMood.lemah => 'Lemah'.tr,
      null => '-',
    };
    final moodColor = switch (mood?.mood) {
      MarketMood.kuat => AppColors.earn,
      MarketMood.lemah => AppColors.spend,
      _ => AppColors.ink2,
    };
    String zoneSub(PriceZone? z) => z == null || z.high == z.low
        ? ''
        : 'sampai @price'.trParams({'price': formatPrice(z.high.round())});
    final tiles = [
      _Tile(
        title: 'TREN'.tr,
        value: trendLabel,
        sub: trend == null ? '' : _maPosition(trend),
        color: trendColor,
      ),
      _Tile(
        title: 'SENTIMEN'.tr,
        value: moodText,
        sub: switch (monthChange(market)) {
          (final change, _) => 'IHSG @pct bln ini'.trParams({
            'pct': formatPercent(change * 100),
          }),
          null => '',
        },
        color: moodColor,
      ),
      _Tile(
        title: 'SUPPORT'.tr,
        value: zones.support == null
            ? '-'
            : formatPrice(zones.support!.low.round()),
        sub: zoneSub(zones.support),
        color: AppColors.earn,
      ),
      _Tile(
        title: 'RESISTANCE'.tr,
        value: zones.resistance == null
            ? '-'
            : formatPrice(zones.resistance!.low.round()),
        sub: zoneSub(zones.resistance),
        color: AppColors.spend,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, tile) in tiles.indexed) ...[
                  if (index > 0)
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.line2,
                    ),
                  Expanded(child: tile),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [
            'Support dan resistance dicari otomatis dari titik balik 60 hari, bisa keliru. Sentimen dari posisi IHSG terhadap MA50 dan MA200.'
                .tr,
            if (news case final n?)
              'Skor kata berita @date: @score, rata-rata dari @scored judul yang memuat kata bermuatan (total @count judul).'
                  .trParams({
                    'date': formatDayMonth(n.day),
                    'score': formatIndicator(n.average, digits: 2),
                    'scored': '${n.scored}',
                    'count': '${n.titles}',
                  }),
          ].join(' '),
          style: AppText.body(size: 10.5, color: AppColors.mut, height: 1.4),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String title;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title $value $sub',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.label(color: AppColors.mut, size: 9.5),
              ),
              const SizedBox(height: 4),
              Text(value, style: AppText.display(size: 16, color: color)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppText.body(
                    size: 10,
                    color: AppColors.ink2,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
