import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../models/daily_bar.dart';
import '../services/price_analysis.dart';
import '../services/technical_reading.dart';
import 'chart_painting.dart';
import 'stock_format.dart';

/// Chart harga dan tiga indikator (volume, Stoch RSI, MACD) dengan satu garis
/// penunjuk hari yang dipakai bersama: sentuh atau geser di chart mana pun,
/// dan pembacaan di semua panel ikut pindah ke hari itu.
class TechnicalSection extends StatelessWidget {
  const TechnicalSection({
    super.key,
    required this.bars,
    required this.onSelect,
    this.selected,
    this.overlay,
    this.facts = const [],
  });

  /// Garis rata-rata, pita Bollinger, dan zona support/resistance dari
  /// `price_history`, null bila riwayat belum termuat.
  final PriceOverlay? overlay;

  /// Fakta singkat di bawah chart harga: (judul, isi).
  final List<ChartFact> facts;

  /// Hari perdagangan yang digambar, terlama dulu.
  final List<DailyBar> bars;

  /// Indeks hari yang disentuh, null berarti hari terakhir. Rincian harga
  /// hari itu tampil di blok tinta di atas halaman, bukan di kartu terpisah.
  final int? selected;

  /// Dipanggil saat chart disentuh atau digeser.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final picked = this.selected;
    final selected = picked != null && picked >= 0 && picked < bars.length
        ? picked
        : null;
    final index = selected ?? bars.length - 1;
    final bar = bars[index];
    final previous = index > 0 ? bars[index - 1] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChartCard(
          title: 'Harga'.tr,
          reading: selected == null && overlay != null
              ? priceSituation(bar, overlay!, index) ?? _priceReading(bar)
              : _priceReading(bar),
          legend: [
            if (overlay != null) ...[
              _LegendKey(
                color: AppColors.accent,
                label: 'MA20',
                value: _price(overlay!.ma20[index]),
              ),
              _LegendKey(
                color: AppColors.ink2,
                label: 'MA50',
                value: _price(overlay!.ma50[index]),
                dashed: true,
              ),
              _LegendKey(
                color: AppColors.mut,
                label: 'Pita bawah Bollinger'.tr,
                value: _price(overlay!.bbLower[index]),
                dashed: true,
              ),
              if (overlay!.zones.support != null)
                _LegendKey(
                  color: AppColors.earn,
                  label: 'Support'.tr,
                  value: '',
                  swatch: true,
                ),
              if (overlay!.zones.resistance != null)
                _LegendKey(
                  color: AppColors.spend,
                  label: 'Resistance'.tr,
                  value: '',
                  swatch: true,
                ),
              if (overlay!.hasLowRsi)
                _LegendKey(
                  color: AppColors.warn,
                  label: 'RSI di bawah 30'.tr,
                  value: '',
                  dot: true,
                ),
              if (overlay!.divergence != null)
                _LegendKey(
                  color: AppColors.warn,
                  label: 'Divergence (kasar)'.tr,
                  value: '',
                  dashed: true,
                ),
            ],
          ],
          height: 220,
          count: bars.length,
          onSelect: onSelect,
          painter: _PricePainter(bars, selected, overlay),
          facts: facts,
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Volume'.tr,
          reading: _volumeReading(bar),
          legend: [
            _LegendKey(
              color: AppColors.ink2,
              label: 'Rata-rata 20 hari'.tr,
              value: bar.volumeMa20 == null ? '-' : formatLot(bar.volumeMa20!),
            ),
            _LegendKey(
              color: AppColors.earn,
              label: 'Volume'.tr,
              value: bar.volumeLot == null ? '-' : formatLot(bar.volumeLot!),
              swatch: true,
            ),
          ],
          height: 96,
          count: bars.length,
          onSelect: onSelect,
          painter: _VolumePainter(bars, selected),
          note: volumeNote(bars),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Stoch RSI 14 14 3 3',
          reading: _stochReading(bar),
          legend: [
            _LegendKey(
              color: AppColors.ink,
              label: 'K',
              value: bar.stochA == null
                  ? '-'
                  : formatIndicator(bar.stochA!, digits: 1),
            ),
            _LegendKey(
              color: AppColors.accent,
              label: 'D',
              value: bar.stochB == null
                  ? '-'
                  : formatIndicator(bar.stochB!, digits: 1),
              dashed: true,
            ),
          ],
          height: 110,
          count: bars.length,
          onSelect: onSelect,
          painter: _StochPainter(bars, selected),
          note: stochNote(bars),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'MACD 12 26 9',
          reading: _macdReading(bar, previous),
          legend: [
            _LegendKey(
              color: AppColors.ink,
              label: 'MACD',
              value: bar.macdA == null ? '-' : formatIndicator(bar.macdA!),
            ),
            _LegendKey(
              color: AppColors.accent,
              label: 'Sinyal'.tr,
              value: bar.macdB == null ? '-' : formatIndicator(bar.macdB!),
              dashed: true,
            ),
            _LegendKey(
              color: (bar.macdHist ?? 0) < 0 ? AppColors.spend : AppColors.earn,
              label: 'Histogram'.tr,
              value: bar.macdHist == null
                  ? '-'
                  : formatIndicator(bar.macdHist!),
              swatch: true,
            ),
          ],
          height: 130,
          count: bars.length,
          onSelect: onSelect,
          painter: _MacdPainter(bars, selected),
          note: macdNote(bars),
        ),
        const SizedBox(height: 10),
        Text(
          '${'Indikator dihitung dari harga penutupan dengan parameter Stockbit. Batang histogram pekat berarti membesar, pudar berarti mengecil. Hari yang ditandai tidak akurat tidak digambar. Ini pembacaan angka, bukan saran.'.tr} ${'Kondisi saat ini, bukan sinyal beli atau jual. Skor model dan batas 10 hari ada di tab Prediksi.'.tr}',
          style: AppText.body(size: 11, color: AppColors.mut, height: 1.4),
        ),
      ],
    );
  }
}

String _price(double? v) => v == null ? '-' : formatPrice(v.round());

/// Data tambahan untuk chart harga, sejajar dengan hari yang digambar.
class PriceOverlay {
  const PriceOverlay({
    required this.ma20,
    required this.ma50,
    required this.bbLower,
    required this.zones,
    this.ma200 = const [],
    this.rsi = const [],
    this.divergence,
  });

  final List<double?> ma20;
  final List<double?> ma50;
  final List<double?> bbLower;
  final SupportResistance zones;

  /// MA200 per hari, hanya untuk kalimat di atas chart (tidak digambar).
  final List<double?> ma200;

  /// RSI 14 per hari; hari dengan RSI di bawah 30 diberi titik.
  final List<double?> rsi;

  /// Divergence kasar yang digambar sebagai garis putus-putus di bawah dua
  /// titik terendah, null bila tidak ada.
  final Divergence? divergence;

  bool get hasLowRsi => rsi.any((v) => v != null && v < 30);
}

/// Kalimat di atas chart harga untuk hari terakhir: jarak ke support dan
/// posisi terhadap MA20, MA50, MA200. Null bila datanya kurang.
String? priceSituation(DailyBar bar, PriceOverlay overlay, int index) {
  final close = bar.close?.toDouble();
  if (close == null) return null;
  final support = overlay.zones.support;
  final first = support != null && close >= support.low
      ? 'Tutup @price, @pct% di atas support.'.trParams({
          'price': formatPrice(close.round()),
          'pct': '${((close / support.high - 1) * 100).round()}',
        })
      : '${'Tutup @price'.trParams({'price': formatPrice(close.round())})}.';
  double? at(List<double?> series) =>
      index < series.length ? series[index] : null;
  final mas = [
    ('MA20', at(overlay.ma20)),
    ('MA50', at(overlay.ma50)),
    ('MA200', at(overlay.ma200)),
  ];
  final known = [
    for (final (name, v) in mas)
      if (v != null) (name, v),
  ];
  String join(List<String> xs) => switch (xs) {
    [] => '',
    [final a] => a,
    [final a, final b] => '$a ${'dan'.tr} $b',
    [...final init, final last] => '${init.join(', ')}, ${'dan'.tr} $last',
  };
  final below = [
    for (final (n, v) in known)
      if (close < v) n,
  ];
  final above = [
    for (final (n, v) in known)
      if (close >= v) n,
  ];
  final String? second = known.isEmpty
      ? null
      : above.isEmpty
      ? 'Masih di bawah @list.'.trParams({'list': join(below)})
      : below.isEmpty
      ? 'Di atas @list.'.trParams({'list': join(above)})
      : 'Di atas @above, di bawah @below.'.trParams({
          'above': join(above),
          'below': join(below),
        });
  return [first, ?second].join(' ');
}

/// Satu kalimat di bawah chart volume: hari terbesar bulan ini.
String? volumeNote(List<DailyBar> bars) {
  final day = biggestVolumeDay(bars);
  final volume = day?.volumeLot;
  if (day == null || volume == null) return null;
  final change = day.changePercent;
  final args = {
    'date': formatDayMonth(day.tradeDate),
    'volume': formatLot(volume),
  };
  if (change == null) {
    return 'Terbesar bulan ini @date (@volume).'.trParams(args);
  }
  return (change >= 0
          ? 'Terbesar bulan ini @date (@volume), hari harga naik @pct%.'
          : 'Terbesar bulan ini @date (@volume), hari harga turun @pct%.')
      .trParams({...args, 'pct': formatIndicator(change.abs(), digits: 1)});
}

/// Satu kalimat di bawah Stoch RSI: berapa hari K menguat atau melemah.
String? stochNote(List<DailyBar> bars) {
  final streak = stochKStreak(bars);
  if (streak == null || streak.days == 0) return null;
  return (streak.rising
          ? 'K menguat @days hari berturut-turut, dari @from (@date).'
          : 'K melemah @days hari berturut-turut, dari @from (@date).')
      .trParams({
        'days': '${streak.days}',
        'from': formatIndicator(streak.fromValue, digits: 1),
        'date': formatDayMonth(streak.fromDate),
      });
}

/// Satu kalimat di bawah MACD: berapa hari histogram memudar atau memekat.
String? macdNote(List<DailyBar> bars) {
  final streak = macdHistStreak(bars);
  if (streak == null) return null;
  return (streak.fading
          ? 'Histogram memudar @days hari berturut-turut sejak @date.'
          : 'Histogram memekat @days hari berturut-turut sejak @date.')
      .trParams({
        'days': '${streak.days}',
        'date': formatDayMonth(streak.since),
      });
}

/// Fakta singkat di bawah chart harga.
/// Satu baris fakta di bawah chart harga. [warn] menambah label "otomatis,
/// bisa keliru" untuk hasil deteksi otomatis yang longgar.
class ChartFact {
  const ChartFact(this.title, this.body, {this.warn = false});

  final String title;
  final String body;
  final bool warn;
}

/// Baris fakta ringkas di bawah chart harga: "Judul · isi", dipisah garis
/// tipis dari chart.
class _FactRows extends StatelessWidget {
  const _FactRows({required this.facts});

  final List<ChartFact> facts;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line2)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final fact in facts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Text.rich(
                  TextSpan(
                    style: AppText.body(
                      size: 12,
                      color: AppColors.ink2,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '${fact.title} · ',
                        style: AppText.body(
                          size: 12,
                          color: AppColors.mut,
                          height: 1.4,
                        ),
                      ),
                      if (fact.warn)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warnSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'otomatis, bisa keliru'.tr,
                              style: AppText.body(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: AppColors.warn,
                              ),
                            ),
                          ),
                        ),
                      TextSpan(text: fact.body),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _priceReading(DailyBar bar) {
  final close = bar.close;
  if (close == null) return 'Harga penutupan belum terbaca.'.tr;
  final change = bar.changePercent;
  return change == null
      ? 'Tutup @price'.trParams({'price': formatPrice(close)})
      : 'Tutup @price (@change)'.trParams({
          'price': formatPrice(close),
          'change': formatPercent(change),
        });
}

String _volumeReading(DailyBar bar) {
  final ratio = bar.volumeRatio;
  final level = TechnicalReading.volumeLevel(ratio);
  if (ratio == null || level == null) return 'Volume belum terbaca.'.tr;
  final word = switch (level) {
    VolumeLevel.farAbove => 'jauh di atas'.tr,
    VolumeLevel.above => 'di atas'.tr,
    VolumeLevel.below => 'di bawah'.tr,
    VolumeLevel.farBelow => 'jauh di bawah'.tr,
  };
  final base = 'Volume @pct% dari rata-rata 20 hari, @level'.trParams({
    'pct': (ratio * 100).round().toString(),
    'level': word,
  });
  return bar.isIntraday
      ? '$base. ${'Hari berjalan, volume masih bertambah.'.tr}'
      : base;
}

String _stochReading(DailyBar bar) {
  if (bar.stochA == null && bar.stochB == null) {
    return 'Stoch RSI belum terbaca.'.tr;
  }
  final zone = switch ((
    TechnicalReading.stochZone(bar.stochA),
    TechnicalReading.stochZone(bar.stochB),
  )) {
    (final a?, final b?) when a == b => a,
    (StochZone _, StochZone _) => null,
    _ => TechnicalReading.stochZone(bar.stochA ?? bar.stochB),
  };
  final zoneText = switch (zone) {
    StochZone.oversold => 'Di area bawah (20 ke bawah)'.tr,
    StochZone.neutral => 'Di area tengah (20 sampai 80)'.tr,
    StochZone.overbought => 'Di area atas (80 ke atas)'.tr,
    null => 'Dua garis berada di area berbeda'.tr,
  };
  final orderText = switch (TechnicalReading.lineOrder(
    bar.stochA,
    bar.stochB,
  )) {
    LineOrder.above => 'K di atas D'.tr,
    LineOrder.below => 'K di bawah D'.tr,
    LineOrder.equal => 'K sama dengan D'.tr,
    null => null,
  };
  return orderText == null ? '$zoneText.' : '$zoneText. $orderText.';
}

String _macdReading(DailyBar bar, DailyBar? previous) {
  final side = TechnicalReading.macdSide(bar);
  final hist = bar.macdHist;
  if (side == null && hist == null) return 'MACD belum terbaca.'.tr;
  final trend = TechnicalReading.histTrend(hist, previous?.macdHist);
  final histText = switch ((hist, trend)) {
    (null, _) => null,
    (0.0, _) => 'Histogram nol'.tr,
    (final double h, HistTrend.growing) when h > 0 =>
      'Histogram positif dan membesar (batang pekat)'.tr,
    (final double h, _) when h > 0 =>
      'Histogram positif dan menyusut (batang pudar)'.tr,
    (_, HistTrend.growing) =>
      'Histogram negatif dan membesar (batang pekat)'.tr,
    _ => 'Histogram negatif dan menyusut (batang pudar)'.tr,
  };
  final orderText = switch (TechnicalReading.lineOrder(bar.macdA, bar.macdB)) {
    LineOrder.above => 'MACD di atas sinyal'.tr,
    LineOrder.below => 'MACD di bawah sinyal'.tr,
    LineOrder.equal => 'MACD sama dengan sinyal'.tr,
    null => null,
  };
  final sideText = switch (side) {
    MacdSide.bothAbove => 'kedua garis di atas nol'.tr,
    MacdSide.bothBelow => 'kedua garis di bawah nol'.tr,
    MacdSide.mixed => 'garis berada di dua sisi nol'.tr,
    null => null,
  };
  final lines = [?orderText, ?sideText].join(', ');
  return [
    ?histText,
    if (lines.isNotEmpty) lines[0].toUpperCase() + lines.substring(1),
  ].map((part) => '$part.').join(' ');
}

/// Kartu satu panel: judul, pembacaan satu kalimat, legenda, lalu gambar.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.reading,
    required this.height,
    required this.count,
    required this.onSelect,
    required this.painter,
    this.legend = const [],
    this.note,
    this.facts = const [],
  });

  /// Satu kalimat biasa di bawah gambar, null bila tidak ada.
  final String? note;

  /// Baris fakta ringkas di bagian bawah kartu.
  final List<ChartFact> facts;

  final String title;
  final String reading;
  final double height;
  final int count;
  final ValueChanged<int> onSelect;
  final CustomPainter painter;
  final List<Widget> legend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.label(color: AppColors.mut, size: 11),
          ),
          const SizedBox(height: 4),
          Text(
            reading,
            style: AppText.body(size: 12.5, color: AppColors.ink2, height: 1.4),
          ),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 14, runSpacing: 4, children: legend),
          ],
          const SizedBox(height: 10),
          Semantics(
            label: '$title. $reading',
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  void select(Offset local) => onSelect(
                    ChartFrame.indexAt(local.dx, constraints.maxWidth, count),
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => select(details.localPosition),
                    onHorizontalDragStart: (details) =>
                        select(details.localPosition),
                    onHorizontalDragUpdate: (details) =>
                        select(details.localPosition),
                    child: SizedBox(
                      height: height,
                      width: double.infinity,
                      child: CustomPaint(painter: painter),
                    ),
                  );
                },
              ),
            ),
          ),
          if (note case final String text) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: AppText.body(size: 12, color: AppColors.ink2, height: 1.4),
            ),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FactRows(facts: facts),
          ],
        ],
      ),
    );
  }
}

/// Satu entri legenda: contoh garis atau kotak, nama, dan nilai hari terpilih.
class _LegendKey extends StatelessWidget {
  const _LegendKey({
    required this.color,
    required this.label,
    required this.value,
    this.dashed = false,
    this.swatch = false,
    this.dot = false,
  });

  final Color color;
  final String label;
  final String value;
  final bool dashed;
  final bool swatch;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 10,
          child: CustomPaint(
            painter: _KeyPainter(
              color: color,
              dashed: dashed,
              swatch: swatch,
              dot: dot,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.body(size: 11, color: AppColors.mut)),
        if (value.isNotEmpty) ...[
          const SizedBox(width: 5),
          Text(
            value,
            style: AppText.mono(
              size: 11.5,
              weight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyPainter extends CustomPainter {
  const _KeyPainter({
    required this.color,
    required this.dashed,
    required this.swatch,
    this.dot = false,
  });

  final Color color;
  final bool dashed;
  final bool swatch;
  final bool dot;

  @override
  void paint(Canvas canvas, Size size) {
    if (dot) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        3,
        Paint()..color = color,
      );
      return;
    }
    if (swatch) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 1, size.width - 4, size.height - 2),
          const Radius.circular(2),
        ),
        Paint()..color = fade(color, 0.6),
      );
      return;
    }
    final paint = linePaint(color);
    final y = size.height / 2;
    if (dashed) {
      paintDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        paint,
        dash: 4,
        gap: 2.5,
      );
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_KeyPainter old) =>
      old.color != color ||
      old.dashed != dashed ||
      old.swatch != swatch ||
      old.dot != dot;
}

bool _sameInputs(List<DailyBar> a, List<DailyBar> b) =>
    identical(a, b) ||
    (a.length == b.length &&
        a.isNotEmpty &&
        identical(a.first, b.first) &&
        identical(a.last, b.last));

/// Warna naik atau turun sebuah hari: tutup dibanding tutup kemarin, atau
/// dibanding buka bila kemarin tidak diketahui.
Color _directionColor(DailyBar bar) {
  final close = bar.close;
  final reference = bar.prevClose ?? bar.open;
  if (close == null || reference == null) return AppColors.mut;
  return close >= reference ? AppColors.earn : AppColors.spend;
}

class _PricePainter extends CustomPainter {
  const _PricePainter(this.bars, this.selected, this.overlay);

  final List<DailyBar> bars;
  final int? selected;
  final PriceOverlay? overlay;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = ChartFrame(size, bars.length);
    var lo = double.infinity;
    var hi = -double.infinity;
    for (final bar in bars) {
      for (final value in [bar.open, bar.high, bar.low, bar.close]) {
        if (value == null) continue;
        lo = math.min(lo, value.toDouble());
        hi = math.max(hi, value.toDouble());
      }
    }
    if (lo > hi) return;
    final extra = overlay;
    if (extra != null) {
      for (final series in [extra.ma20, extra.ma50, extra.bbLower]) {
        for (final value in series) {
          if (value == null) continue;
          lo = math.min(lo, value);
          hi = math.max(hi, value);
        }
      }
      for (final zone in [extra.zones.support, extra.zones.resistance]) {
        if (zone == null) continue;
        lo = math.min(lo, zone.low);
        hi = math.max(hi, zone.high);
      }
    }
    final pad = hi == lo ? lo * 0.01 + 1 : (hi - lo) * 0.08;
    lo -= pad;
    hi += pad;

    for (final t in const [0.0, 0.5, 1.0]) {
      final value = lo + (hi - lo) * t;
      paintGridLine(
        canvas,
        frame,
        frame.yOf(value, lo, hi),
        formatPrice(value.round()),
      );
    }

    if (extra != null) {
      for (final (zone, color) in [
        (extra.zones.support, AppColors.earn),
        (extra.zones.resistance, AppColors.spend),
      ]) {
        if (zone == null) continue;
        final top = frame.yOf(zone.high, lo, hi);
        final bottom = frame.yOf(zone.low, lo, hi);
        canvas.drawRect(
          Rect.fromLTRB(
            frame.plot.left,
            top - 1.5,
            frame.plot.right,
            math.max(bottom, top + 3) + 1.5,
          ),
          Paint()..color = color.withValues(alpha: 0.13),
        );
      }
      paintSeries(
        canvas,
        frame,
        extra.bbLower,
        lo,
        hi,
        linePaint(AppColors.mut, width: 1.1),
        dashed: true,
      );
      paintSeries(
        canvas,
        frame,
        extra.ma50,
        lo,
        hi,
        linePaint(AppColors.ink2, width: 1.4),
        dashed: true,
      );
      paintSeries(
        canvas,
        frame,
        extra.ma20,
        lo,
        hi,
        linePaint(AppColors.accent, width: 1.4),
      );
    }

    final bodyWidth = (frame.step * 0.62).clamp(1.5, 9.0);
    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      final close = bar.close;
      if (close == null) continue;
      final open = bar.open ?? bar.prevClose ?? close;
      final high = bar.high ?? math.max(open, close);
      final low = bar.low ?? math.min(open, close);
      final color = close == open
          ? AppColors.ink2
          : (close > open ? AppColors.earn : AppColors.spend);
      final x = frame.xOf(i);
      final fill = Paint()..color = color;
      canvas.drawLine(
        Offset(x, frame.yOf(high.toDouble(), lo, hi)),
        Offset(x, frame.yOf(low.toDouble(), lo, hi)),
        Paint()
          ..color = color
          ..strokeWidth = 1.2,
      );
      final top = frame.yOf(math.max(open, close).toDouble(), lo, hi);
      final bottom = frame.yOf(math.min(open, close).toDouble(), lo, hi);
      canvas.drawRect(
        Rect.fromLTRB(
          x - bodyWidth / 2,
          top,
          x + bodyWidth / 2,
          math.max(bottom, top + 1.5),
        ),
        fill,
      );
    }

    if (extra != null) _paintRsiMarks(canvas, frame, extra, lo, hi);

    final last = bars.last.close;
    if (last != null) {
      final y = frame.yOf(last.toDouble(), lo, hi);
      paintDashedLine(
        canvas,
        Offset(frame.plot.left, y),
        Offset(frame.plot.right, y),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
      paintValueTag(canvas, frame, y, formatPrice(last));
    }
    paintCrosshair(canvas, frame, selected);
  }

  /// Titik di bawah hari dengan RSI di bawah 30, dan garis divergence di
  /// bawah dua titik terendahnya bila keduanya ada di rentang chart.
  void _paintRsiMarks(
    Canvas canvas,
    ChartFrame frame,
    PriceOverlay extra,
    double lo,
    double hi,
  ) {
    double lowOf(int i) {
      final bar = bars[i];
      return (bar.low ?? bar.close ?? 0).toDouble();
    }

    final dot = Paint()..color = AppColors.warn;
    for (var i = 0; i < bars.length && i < extra.rsi.length; i++) {
      final r = extra.rsi[i];
      if (r == null || r >= 30 || bars[i].close == null) continue;
      canvas.drawCircle(
        Offset(frame.xOf(i), frame.yOf(lowOf(i), lo, hi) + 6),
        2.6,
        dot,
      );
    }
    final div = extra.divergence;
    if (div == null) return;
    int find(DateTime d) => bars.indexWhere(
      (b) =>
          b.tradeDate.year == d.year &&
          b.tradeDate.month == d.month &&
          b.tradeDate.day == d.day,
    );
    final a = find(div.firstDate);
    final b = find(div.secondDate);
    if (a < 0 || b < 0) return;
    paintDashedLine(
      canvas,
      Offset(frame.xOf(a), frame.yOf(div.firstPrice, lo, hi) + 11),
      Offset(frame.xOf(b), frame.yOf(div.secondPrice, lo, hi) + 11),
      linePaint(AppColors.warn, width: 1.2),
      dash: 3,
      gap: 2,
    );
  }

  @override
  bool shouldRepaint(_PricePainter old) =>
      old.selected != selected ||
      !identical(old.overlay, overlay) ||
      !_sameInputs(old.bars, bars);
}

class _VolumePainter extends CustomPainter {
  const _VolumePainter(this.bars, this.selected);

  final List<DailyBar> bars;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = ChartFrame(size, bars.length);
    var peak = 0.0;
    for (final bar in bars) {
      peak = math.max(
        peak,
        math.max(bar.volumeLot ?? 0, bar.volumeMa20 ?? 0).toDouble(),
      );
    }
    if (peak <= 0) return;
    final hi = peak * 1.08;
    paintGridLine(canvas, frame, frame.yOf(hi, 0, hi), formatLot(hi.round()));
    paintGridLine(canvas, frame, frame.yOf(0, 0, hi), '0');

    final barWidth = (frame.step * 0.62).clamp(1.5, 9.0);
    for (var i = 0; i < bars.length; i++) {
      final volume = bars[i].volumeLot;
      if (volume == null) continue;
      final x = frame.xOf(i);
      canvas.drawRect(
        Rect.fromLTRB(
          x - barWidth / 2,
          frame.yOf(volume.toDouble(), 0, hi),
          x + barWidth / 2,
          frame.yOf(0, 0, hi),
        ),
        Paint()..color = fade(_directionColor(bars[i]), 0.6),
      );
    }
    paintSeries(
      canvas,
      frame,
      [for (final bar in bars) bar.volumeMa20?.toDouble()],
      0,
      hi,
      linePaint(AppColors.ink2, width: 1.4),
    );
    paintCrosshair(canvas, frame, selected);
  }

  @override
  bool shouldRepaint(_VolumePainter old) =>
      old.selected != selected || !_sameInputs(old.bars, bars);
}

class _StochPainter extends CustomPainter {
  const _StochPainter(this.bars, this.selected);

  final List<DailyBar> bars;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = ChartFrame(size, bars.length);
    const lo = 0.0;
    const hi = 100.0;
    final band = Rect.fromLTRB(
      frame.plot.left,
      frame.yOf(80, lo, hi),
      frame.plot.right,
      frame.yOf(20, lo, hi),
    );
    canvas.drawRect(band, Paint()..color = fade(AppColors.paper2, 0.7));
    paintGridLine(canvas, frame, frame.yOf(80, lo, hi), '80', dashed: true);
    paintGridLine(canvas, frame, frame.yOf(20, lo, hi), '20', dashed: true);
    paintSeries(
      canvas,
      frame,
      [for (final b in bars) b.stochA],
      lo,
      hi,
      linePaint(AppColors.ink),
    );
    paintSeries(
      canvas,
      frame,
      [for (final b in bars) b.stochB],
      lo,
      hi,
      linePaint(AppColors.accent),
      dashed: true,
    );
    paintCrosshair(canvas, frame, selected);
  }

  @override
  bool shouldRepaint(_StochPainter old) =>
      old.selected != selected || !_sameInputs(old.bars, bars);
}

class _MacdPainter extends CustomPainter {
  const _MacdPainter(this.bars, this.selected);

  final List<DailyBar> bars;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = ChartFrame(size, bars.length, bottomPad: 20);
    // Skala tidak simetris tapi selalu memuat nol, agar garis nol dan
    // batang histogram tetap terbaca walau kedua garis jauh di satu sisi.
    var lo = 0.0;
    var hi = 0.0;
    for (final bar in bars) {
      for (final value in [bar.macdA, bar.macdB, bar.macdHist]) {
        if (value == null) continue;
        lo = math.min(lo, value);
        hi = math.max(hi, value);
      }
    }
    if (lo == hi) {
      paintDateAxis(
        canvas,
        frame,
        formatDayMonth(bars.first.tradeDate),
        formatDayMonth(bars.last.tradeDate),
      );
      return;
    }
    final pad = (hi - lo) * 0.12;
    if (hi > 0) hi += pad;
    if (lo < 0) lo -= pad;
    final digits = math.max(hi.abs(), lo.abs()) < 10 ? 1 : 0;
    final zeroY = frame.yOf(0, lo, hi);
    // Label batas dilewati bila terlalu dekat dengan label nol.
    for (final edge in [hi, lo]) {
      final y = frame.yOf(edge, lo, hi);
      if ((y - zeroY).abs() < 14) continue;
      paintGridLine(canvas, frame, y, formatIndicator(edge, digits: digits));
    }
    canvas.drawLine(
      Offset(frame.plot.left, zeroY),
      Offset(frame.plot.right, zeroY),
      Paint()
        ..color = AppColors.ink2
        ..strokeWidth = 1,
    );
    paintText(canvas, '0', Offset(frame.plot.right + 6, zeroY));

    final barWidth = (frame.step * 0.62).clamp(1.5, 9.0);
    for (var i = 0; i < bars.length; i++) {
      final hist = bars[i].macdHist;
      if (hist == null) continue;
      final x = frame.xOf(i);
      final y = frame.yOf(hist, lo, hi);
      // Pekat saat batang membesar dari hari sebelumnya, pudar saat mengecil.
      final trend = TechnicalReading.histTrend(
        hist,
        i > 0 ? bars[i - 1].macdHist : null,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          x - barWidth / 2,
          math.min(y, zeroY),
          x + barWidth / 2,
          math.max(y, zeroY),
        ),
        Paint()
          ..color = fade(
            hist >= 0 ? AppColors.earn : AppColors.spend,
            trend == HistTrend.shrinking ? 0.32 : 0.85,
          ),
      );
    }
    paintSeries(
      canvas,
      frame,
      [for (final b in bars) b.macdA],
      lo,
      hi,
      linePaint(AppColors.ink),
    );
    paintSeries(
      canvas,
      frame,
      [for (final b in bars) b.macdB],
      lo,
      hi,
      linePaint(AppColors.accent),
      dashed: true,
    );
    paintCrosshair(canvas, frame, selected);
    paintDateAxis(
      canvas,
      frame,
      formatDayMonth(bars.first.tradeDate),
      formatDayMonth(bars.last.tradeDate),
    );
  }

  @override
  bool shouldRepaint(_MacdPainter old) =>
      old.selected != selected || !_sameInputs(old.bars, bars);
}
