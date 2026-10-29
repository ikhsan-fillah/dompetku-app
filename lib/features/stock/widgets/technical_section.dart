import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../models/daily_bar.dart';
import '../services/technical_reading.dart';
import 'chart_painting.dart';
import 'stock_format.dart';

/// Chart harga dan tiga indikator (volume, Stoch RSI, MACD) dengan satu garis
/// penunjuk hari yang dipakai bersama: sentuh atau geser di chart mana pun,
/// dan pembacaan di semua panel ikut pindah ke hari itu.
class TechnicalSection extends StatefulWidget {
  const TechnicalSection({super.key, required this.bars});

  /// Hari perdagangan yang digambar, terlama dulu.
  final List<DailyBar> bars;

  @override
  State<TechnicalSection> createState() => _TechnicalSectionState();
}

class _TechnicalSectionState extends State<TechnicalSection> {
  final _selected = ValueNotifier<int?>(null);

  @override
  void didUpdateWidget(TechnicalSection old) {
    super.didUpdateWidget(old);
    // Panjang chart berubah: indeks lama tidak berarti lagi.
    if (old.bars.length != widget.bars.length) _selected.value = null;
  }

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  void _select(int index) => _selected.value = index;

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    return ValueListenableBuilder<int?>(
      valueListenable: _selected,
      builder: (context, selected, _) {
        final bar = bars[selected ?? bars.length - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DayReadout(
              bar: selected == null ? null : bars[selected],
              onClear: () => _selected.value = null,
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Harga'.tr,
              reading: _priceReading(bar),
              height: 200,
              count: bars.length,
              onSelect: _select,
              painter: _PricePainter(bars, selected),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Volume'.tr,
              reading: _volumeReading(bar),
              legend: [
                _LegendKey(
                  color: AppColors.ink2,
                  label: 'Rata-rata 20 hari'.tr,
                  value: bar.volumeMa20 == null
                      ? '-'
                      : formatLot(bar.volumeMa20!),
                ),
                _LegendKey(
                  color: AppColors.earn,
                  label: 'Volume'.tr,
                  value: bar.volumeLot == null
                      ? '-'
                      : formatLot(bar.volumeLot!),
                  swatch: true,
                ),
              ],
              height: 96,
              count: bars.length,
              onSelect: _select,
              painter: _VolumePainter(bars, selected),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Stoch RSI'.tr,
              reading: _stochReading(bar),
              legend: [
                _LegendKey(
                  color: AppColors.ink,
                  label: 'Garis a'.tr,
                  value: bar.stochA == null
                      ? '-'
                      : formatIndicator(bar.stochA!, digits: 1),
                ),
                _LegendKey(
                  color: AppColors.accent,
                  label: 'Garis b'.tr,
                  value: bar.stochB == null
                      ? '-'
                      : formatIndicator(bar.stochB!, digits: 1),
                  dashed: true,
                ),
              ],
              height: 110,
              count: bars.length,
              onSelect: _select,
              painter: _StochPainter(bars, selected),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'MACD'.tr,
              reading: _macdReading(bar),
              legend: [
                _LegendKey(
                  color: AppColors.ink,
                  label: 'Garis a'.tr,
                  value: bar.macdA == null ? '-' : formatIndicator(bar.macdA!),
                ),
                _LegendKey(
                  color: AppColors.accent,
                  label: 'Garis b'.tr,
                  value: bar.macdB == null ? '-' : formatIndicator(bar.macdB!),
                  dashed: true,
                ),
                _LegendKey(
                  color: AppColors.earn,
                  label: 'Histogram'.tr,
                  value: bar.macdHist == null
                      ? '-'
                      : formatIndicator(bar.macdHist!),
                  swatch: true,
                ),
              ],
              height: 130,
              count: bars.length,
              onSelect: _select,
              painter: _MacdPainter(bars, selected),
            ),
            const SizedBox(height: 10),
            Text(
              'Nama garis a dan b (MACD dan sinyal, K dan D) belum dipastikan dari legenda Stockbit, jadi dinamai netral. Hari yang ditandai tidak akurat tidak digambar. Ini pembacaan angka, bukan saran.'
                  .tr,
              style: AppText.body(size: 11, color: AppColors.mut, height: 1.4),
            ),
          ],
        );
      },
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
  final zone = switch ((
    TechnicalReading.stochZone(bar.stochA),
    TechnicalReading.stochZone(bar.stochB),
  )) {
    (final a?, final b?) when a == b => a,
    (StochZone _, StochZone _) => null,
    _ => TechnicalReading.stochZone(bar.stochA ?? bar.stochB),
  };
  if (bar.stochA == null && bar.stochB == null) {
    return 'Stoch RSI belum terbaca.'.tr;
  }
  return switch (zone) {
    StochZone.oversold => 'Di area bawah (20 ke bawah)'.tr,
    StochZone.neutral => 'Di area tengah (20 sampai 80)'.tr,
    StochZone.overbought => 'Di area atas (80 ke atas)'.tr,
    null => 'Dua garis berada di area berbeda'.tr,
  };
}

String _macdReading(DailyBar bar) {
  final side = TechnicalReading.macdSide(bar);
  final hist = bar.macdHist;
  if (side == null && hist == null) return 'MACD belum terbaca.'.tr;
  final histText = switch (hist) {
    null => '',
    > 0 => '${'Histogram positif'.tr}. ',
    < 0 => '${'Histogram negatif'.tr}. ',
    _ => '${'Histogram nol'.tr}. ',
  };
  final sideText = switch (side) {
    MacdSide.bothAbove => 'Kedua garis di atas nol'.tr,
    MacdSide.bothBelow => 'Kedua garis di bawah nol'.tr,
    MacdSide.mixed => 'Garis berada di dua sisi nol'.tr,
    null => '',
  };
  return '$histText$sideText'.trim();
}

/// Rincian satu hari yang dipilih, atau petunjuk bila belum ada yang dipilih.
class _DayReadout extends StatelessWidget {
  const _DayReadout({required this.bar, required this.onClear});

  final DailyBar? bar;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final day = bar;
    if (day == null) {
      return AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: AppColors.paper2,
        child: Row(
          children: [
            const Icon(LucideIcons.pointer, size: 18, color: AppColors.ink2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sentuh atau geser di chart untuk melihat harga dan indikator tiap hari.'
                    .tr,
                style: AppText.body(
                  size: 12,
                  color: AppColors.ink2,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    String price(int? value) => value == null ? '-' : formatPrice(value);
    final change = day.changePercent;
    final items = [
      ('Buka'.tr, price(day.open), AppColors.ink),
      ('Tertinggi'.tr, price(day.high), AppColors.ink),
      ('Terendah'.tr, price(day.low), AppColors.ink),
      ('Tutup'.tr, price(day.close), AppColors.ink),
      (
        'Perubahan'.tr,
        change == null ? '-' : formatPercent(change),
        switch (change) {
          null => AppColors.ink,
          > 0 => AppColors.earn,
          < 0 => AppColors.spend,
          _ => AppColors.ink,
        },
      ),
      (
        'Volume'.tr,
        day.volumeLot == null ? '-' : formatLot(day.volumeLot!),
        AppColors.ink,
      ),
    ];
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatShortDate(day.tradeDate),
                    style: AppText.display(size: 16),
                  ),
                  if (day.isIntraday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warnSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'intraday'.tr,
                        style: AppText.body(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.warn,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(onPressed: onClear, child: Text('Hari terakhir'.tr)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                for (var start = 0; start < items.length; start += 3)
                  Padding(
                    padding: EdgeInsets.only(top: start == 0 ? 0 : 10),
                    child: Row(
                      children: [
                        for (final (label, value, color)
                            in items.skip(start).take(3))
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: AppText.label(size: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  value,
                                  style: AppText.mono(
                                    size: 13.5,
                                    weight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
  });

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
  });

  final Color color;
  final String label;
  final String value;
  final bool dashed;
  final bool swatch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 10,
          child: CustomPaint(
            painter: _KeyPainter(color: color, dashed: dashed, swatch: swatch),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.body(size: 11, color: AppColors.mut)),
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
    );
  }
}

class _KeyPainter extends CustomPainter {
  const _KeyPainter({
    required this.color,
    required this.dashed,
    required this.swatch,
  });

  final Color color;
  final bool dashed;
  final bool swatch;

  @override
  void paint(Canvas canvas, Size size) {
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
      old.color != color || old.dashed != dashed || old.swatch != swatch;
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
  const _PricePainter(this.bars, this.selected);

  final List<DailyBar> bars;
  final int? selected;

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

  @override
  bool shouldRepaint(_PricePainter old) =>
      old.selected != selected || !_sameInputs(old.bars, bars);
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
    var limit = 0.0;
    for (final bar in bars) {
      for (final value in [bar.macdA, bar.macdB, bar.macdHist]) {
        if (value != null) limit = math.max(limit, value.abs());
      }
    }
    if (limit == 0) {
      paintDateAxis(
        canvas,
        frame,
        formatDayMonth(bars.first.tradeDate),
        formatDayMonth(bars.last.tradeDate),
      );
      return;
    }
    limit *= 1.12;
    final digits = limit < 10 ? 1 : 0;
    paintGridLine(
      canvas,
      frame,
      frame.yOf(limit, -limit, limit),
      formatIndicator(limit, digits: digits),
    );
    paintGridLine(
      canvas,
      frame,
      frame.yOf(-limit, -limit, limit),
      formatIndicator(-limit, digits: digits),
    );
    final zeroY = frame.yOf(0, -limit, limit);
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
      final y = frame.yOf(hist, -limit, limit);
      canvas.drawRect(
        Rect.fromLTRB(
          x - barWidth / 2,
          math.min(y, zeroY),
          x + barWidth / 2,
          math.max(y, zeroY),
        ),
        Paint()
          ..color = fade(hist >= 0 ? AppColors.earn : AppColors.spend, 0.6),
      );
    }
    paintSeries(
      canvas,
      frame,
      [for (final b in bars) b.macdA],
      -limit,
      limit,
      linePaint(AppColors.ink),
    );
    paintSeries(
      canvas,
      frame,
      [for (final b in bars) b.macdB],
      -limit,
      limit,
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
