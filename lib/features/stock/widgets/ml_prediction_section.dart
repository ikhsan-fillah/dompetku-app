import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/ml_cycle.dart';
import '../models/ml_prediction.dart';
import '../models/price_point.dart';
import '../services/prediction_window.dart';
import '../services/price_analysis.dart';
import 'chart_painting.dart';
import 'stock_format.dart';

/// Nama fitur model teknikal dalam bahasa yang mudah dibaca. Fitur yang tidak
/// ada di daftar ini ditampilkan apa adanya.
const _featureLabels = <String, String>{
  'rsi': 'RSI 14',
  'stochK': 'Stoch RSI %K',
  'stochKminusD': 'Stoch %K-%D',
  'macdHistPct': 'Histogram MACD',
  'macdPct': 'MACD',
  'distSma20': 'Jarak ke MA20',
  'distSma50': 'Jarak ke MA50',
  'sma20vs50': 'MA20 terhadap MA50',
  'volumeRatio': 'Volume',
  'bbZ': 'Posisi Bollinger',
};

/// Berapa faktor terbesar yang diberi tanda + atau − per model; sisanya
/// ditandai "kecil".
const _topFactors = 4;

/// Volatilitas 20 hari dianggap jauh di atas biasanya bila lebih dari
/// sekian kali volatilitas setahun.
const _wideBarrierRatio = 1.5;

/// Hasil model ML satu saham dalam urutan yang dibaca dari atas: satu angka
/// besar (skor dibanding rata-rata), satu chart dua batas, faktor yang
/// memengaruhi skor, lalu seberapa bisa dipercaya. Kondisi harga dan
/// indikator ada di tab Chart supaya tidak dobel. Isinya penyaring, bukan
/// rekomendasi beli atau jual.
class MlPredictionCard extends StatelessWidget {
  const MlPredictionCard({
    super.key,
    required this.prediction,
    this.matured,
    this.pastPredictions = const [],
    this.cycles = const [],
    this.history = const [],
  });

  final MlPrediction prediction;

  /// Prediksi lama yang hasil nyatanya sudah dihitung, null bila belum ada.
  final MlPrediction? matured;

  /// Prediksi sebelumnya dari model aktif, terbaru dulu. Tiap prediksi punya
  /// jendela sendiri yang tetap sejak tanggal sinyalnya.
  final List<MlPrediction> pastPredictions;

  /// Siklus 10 hari bursa saham ini, terbaru dulu. Bila tidak kosong, siklus
  /// pertama adalah yang sedang dibaca dan [prediction] adalah prediksi 10
  /// harinya; sisanya jadi riwayat siklus. Kosong berarti tampilan prediksi
  /// harian seperti semula.
  final List<MlCycle> cycles;

  /// Riwayat harga saham ini dari `price_history`, terlama dulu. Dipakai
  /// untuk chart dua batas dan perbandingan volatilitas; boleh kosong.
  final List<PricePoint> history;

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final trained = p.modelTrainedAt;
    final old = matured;
    final oldOutcome = old?.outcome;
    final window = PredictionWindow.of(p, history);
    final cycle = cycles.firstOrNull;
    final fiveDrivers = cycle?.fiveDay?.drivers ?? const <MlDriver>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (cycle == null
                  ? '${'Data harga'.tr} ${formatShortDate(p.tradeDate)}'
                  : 'Sinyal @date · siklus 10 hari bursa'.trParams({
                      'date': formatShortDate(p.tradeDate),
                    }))
              .toUpperCase(),
          style: AppText.mono(
            size: 11.5,
            color: AppColors.ink2,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${'Sinyal model'.tr} '),
              TextSpan(
                text: 'penyaring.'.tr,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          style: AppText.display(size: 30, height: 1.05, letterSpacing: -0.8),
        ),
        const SizedBox(height: 14),
        _ScoreCard(prediction: p, fiveDay: cycle?.fiveDay),
        const SizedBox(height: AppSpacing.gap),
        _BarrierCard(
          prediction: p,
          history: history,
          window: window,
          fiveDay: cycle?.fiveDay,
        ),
        if (p.drivers.isNotEmpty || fiveDrivers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.gap),
          _FactorsCard(
            ten: p.topDrivers(_topFactors),
            five: [...fiveDrivers]
              ..sort(
                (a, b) => b.contribution.abs().compareTo(a.contribution.abs()),
              ),
            hasFiveDay: cycle?.fiveDay != null,
          ),
        ],
        if (cycle != null) ...[
          const SizedBox(height: AppSpacing.gap),
          _CycleStatusCard(cycle: cycle, window: window),
        ],
        const SizedBox(height: AppSpacing.gap),
        if (cycle == null && old != null && oldOutcome != null) ...[
          _OutcomePanel(prediction: old, outcome: oldOutcome),
          const SizedBox(height: AppSpacing.gap),
        ],
        if (cycles.length > 1) ...[
          _CycleHistoryCard(cycles: cycles.skip(1).toList()),
          const SizedBox(height: AppSpacing.gap),
        ] else if (cycle == null &&
            pastPredictions.any((x) => x.tradeDate != p.tradeDate)) ...[
          _HistoryCard(
            current: p,
            predictions: pastPredictions,
            history: history,
          ),
          const SizedBox(height: AppSpacing.gap),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Text(
            'Tren, support, resistance, sentimen pasar, dan indikator ada di tab Chart.'
                .tr,
            style: AppText.body(
              size: 12.5,
              color: AppColors.ink2,
              height: 1.45,
            ),
          ),
        ),
        if (cycle == null && (old == null || oldOutcome == null)) ...[
          const SizedBox(height: 14),
          Text(
            '${'Hasil nyata muncul setelah prediksi genap'.tr} '
            '${p.horizonDays} ${'hari bursa'.tr}.',
            style: AppText.body(size: 12, height: 1.4, color: AppColors.ink2),
          ),
        ],
        const SizedBox(height: 8),
        if (cycle == null)
          Text(
            '${'Model dilatih'.tr} '
            '${trained == null ? '-' : formatShortDate(trained)} · '
            '${p.modelVersion}',
            style: AppText.mono(size: 10.5, color: AppColors.mut),
          )
        else
          Text(
            [
              '${'10 hari'.tr}: ${cycle.tenDay.model}',
              if (cycle.fiveDay case final five?)
                '${'5 hari'.tr}: ${five.model}',
            ].join('\n'),
            style: AppText.mono(size: 10.5, color: AppColors.mut, height: 1.5),
          ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(LucideIcons.info, size: 14, color: AppColors.ink2),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Penyaring informasi, bukan rekomendasi beli atau jual. Bukan nasihat keuangan.'
                    .tr,
                style: AppText.body(size: 12, color: AppColors.ink2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Persen bertanda untuk hasil, mis. -0,0021 menjadi -0,2%.
String _signed(double fraction) => formatPercent(fraction * 100);

/// Pecahan 0 sampai 1 menjadi hitungan bulat dari 100.
int _outOf100(double fraction) =>
    (fraction * 100).round().clamp(0, 100).toInt();

Color _signColor(double v) => v > 0
    ? AppColors.earn
    : v < 0
    ? AppColors.spend
    : AppColors.ink;

/// Arti angka fitur dalam kalimat pendek, null bila tidak ada terjemahan
/// yang jelas. Jarak ke MA adalah harga dibagi MA dikurangi 1. RSI disimpan
/// sebagai pecahan 0 sampai 1, jadi dikali 100 bila nilainya kecil.
String? _driverMeaning(MlDriver? d) {
  final v = d?.value;
  if (d == null || v == null) return null;
  String pct(double x) => '${formatIndicator(x.abs() * 100, digits: 1)}%';
  switch (d.feature) {
    case 'distSma20':
    case 'distSma50':
      final ma = d.feature == 'distSma20' ? 'MA20' : 'MA50';
      return (v < 0 ? 'harga @pct di bawah @ma' : 'harga @pct di atas @ma')
          .trParams({'pct': pct(v), 'ma': ma});
    case 'sma20vs50':
      return (v < 0 ? 'MA20 @pct di bawah MA50' : 'MA20 @pct di atas MA50')
          .trParams({'pct': pct(v)});
    case 'volumeRatio':
      // Fitur ini logaritma rasio volume hari sinyal terhadap rata-rata 20 hari.
      return 'sekitar @pct% dari rata-rata 20 hari'.trParams({
        'pct': '${(math.exp(v) * 100).round()}',
      });
    case 'rsi':
      final rsi = v <= 1.5 ? v * 100 : v;
      return formatIndicator(rsi, digits: 1);
    case 'bbZ':
      if (v <= -1) return 'dekat pita bawah'.tr;
      if (v >= 1) return 'dekat pita atas'.tr;
      return 'di tengah pita'.tr;
  }
  return null;
}

/// Kartu putih bergaris tipis, sama dengan kartu lain di modul Saham.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.card),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppText.mono(size: 11.5, color: AppColors.ink2, letterSpacing: 0.9),
  );
}

/// Judul kecil kapital di dalam kartu.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppText.label(color: AppColors.mut, size: 11),
  );
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.style});

  final _SignalStyle style;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: style.soft,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      style.label,
      style: AppText.body(
        size: 11.5,
        weight: FontWeight.w700,
        color: style.color,
      ),
    ),
  );
}

/// Kartu 1: skor saham ini dibanding rata-rata, dengan pertanyaan yang
/// dijawab model dalam harga rupiah.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.prediction, this.fiveDay});

  final MlPrediction prediction;

  /// Prediksi 5 hari dari siklus yang sama, null bila tidak ada.
  final MlCycleLeg? fiveDay;

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final five = fiveDay;
    final signal = _SignalStyle.of(p.signal);
    final close = p.closePrice;
    final score = _outOf100(p.probUp);
    final base = _outOf100(p.baseRate);
    String barrier(double pct) => close == null
        ? _signed(pct)
        : 'Rp ${formatPrice((close * (1 + pct)).round())} (${_signed(pct)})';
    final question =
        'Dalam @days hari bursa, mana yang tersentuh lebih dulu: @up atau @down? Model memperkirakan batas atas lebih dulu sekitar @score dari 100 kali.'
            .trParams({
              'days': '${p.horizonDays}',
              'up': barrier(p.upperPct),
              'down': barrier(p.lowerPct),
              'score': '$score',
            });
    final fiveQuestion = five == null
        ? ''
        : ' ${'Untuk 5 hari pertama, dengan batas yang lebih sempit di dalam jendela itu: @score dari 100.'.trParams({'score': '${_outOf100(five.probUp)}'})}';
    return _Panel(
      children: [
        Row(
          children: [
            Expanded(child: _Eyebrow('Kemungkinan batas atas dulu'.tr)),
            _SignalChip(style: signal),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: _BigNumber(
                  value: score,
                  caption: five == null
                      ? '@ticker pada hari sinyal'.trParams({
                          'ticker': p.ticker,
                        })
                      : '@ticker, @days hari'.trParams({
                          'ticker': p.ticker,
                          'days': '${p.horizonDays}',
                        }),
                  size: 56,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 14),
              const VerticalDivider(width: 1, color: AppColors.line2),
              const SizedBox(width: 14),
              if (five != null) ...[
                Flexible(
                  child: _BigNumber(
                    value: _outOf100(five.probUp),
                    caption: '@ticker, @days hari'.trParams({
                      'ticker': p.ticker,
                      'days': '${MlCycle.reviseDay}',
                    }),
                    size: 30,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 14),
                const VerticalDivider(width: 1, color: AppColors.line2),
                const SizedBox(width: 14),
              ],
              Flexible(
                child: _BigNumber(
                  value: base,
                  caption: five == null
                      ? 'rata-rata semua saham'.tr
                      : 'rata-rata saham'.tr,
                  size: 30,
                  color: AppColors.mut,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$question$fiveQuestion',
            style: AppText.body(size: 13, color: AppColors.ink2, height: 1.5),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          signal.headline.trParams({'ticker': p.ticker}),
          style: AppText.body(size: 12.5, color: AppColors.ink2, height: 1.45),
        ),
        if (p.inUniverse == false) ...[
          const SizedBox(height: 10),
          Text(
            'Saham ini di luar data latih model, jadi skornya kurang bisa dipercaya.'
                .tr,
            style: AppText.body(
              size: 12,
              height: 1.4,
              weight: FontWeight.w700,
              color: AppColors.warn,
            ),
          ),
        ],
      ],
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.caption,
    required this.size,
    required this.color,
  });

  final int value;
  final String caption;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$value'),
              TextSpan(
                text: '%',
                style: TextStyle(fontSize: size * 0.43, letterSpacing: 0),
              ),
            ],
          ),
          style: AppText.display(
            size: size,
            color: color,
            height: 0.95,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(caption, style: AppText.body(size: 12, color: AppColors.ink2)),
      ],
    );
  }
}

/// Kartu 2: harga sebulan terakhir dan batas prediksi. Bila ada prediksi 5
/// hari, batasnya digambar sebagai kotak lebih kecil di dalam batas 10 hari.
/// Di bawahnya ubin persen tiap jendela dan catatan bila batas jauh lebih
/// lebar dari biasanya.
class _BarrierCard extends StatelessWidget {
  const _BarrierCard({
    required this.prediction,
    required this.history,
    required this.window,
    this.fiveDay,
  });

  final MlPrediction prediction;
  final List<PricePoint> history;

  /// Jendela tetap prediksi ini, dihitung dari tanggal sinyalnya.
  final PredictionWindow window;

  /// Prediksi 5 hari dari siklus yang sama, null bila tidak ada.
  final MlCycleLeg? fiveDay;

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final five = fiveDay;
    // Garis harga berhenti di hari sinyal, bukan di hari data terbaru, supaya
    // jendela 10 hari tetap dan prediksi lama tidak ikut bergeser.
    final upToSignal = historyUpTo(history, p.tradeDate);
    final recent = upToSignal.length > 22
        ? upToSignal.sublist(upToSignal.length - 22)
        : upToSignal;
    final close = p.closePrice ?? recent.lastOrNull?.close;
    final sd20 = dailyVolatility(history, 20);
    final sdYear = dailyVolatility(history, 250);
    final wide =
        sd20 != null && sdYear != null && sd20 > sdYear * _wideBarrierRatio;
    final yearBarrier = sdYear == null
        ? null
        : barrierFromVolatility(sdYear, p.horizonDays);
    return _Panel(
      children: [
        _Eyebrow(
          five == null
              ? 'Dua batas yang diuji'.tr
              : 'Batas 5 hari di dalam batas 10 hari'.tr,
        ),
        if (close != null && recent.length >= 5) ...[
          const SizedBox(height: 10),
          Semantics(
            label:
                (five == null
                        ? 'Harga sebulan sampai hari sinyal dan dua batas @days hari'
                        : 'Harga sebulan sampai hari sinyal, batas 5 hari di dalam batas @days hari')
                    .trParams({'days': '${p.horizonDays}'}),
            child: ExcludeSemantics(
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BarrierChartPainter(
                    closes: [for (final x in recent) x.close],
                    first: recent.first.date,
                    last: recent.last.date,
                    realized: [for (final x in window.realized) x.close],
                    horizon: p.horizonDays,
                    windowEnd: window.endDate,
                    close: close,
                    upper: close * (1 + p.upperPct),
                    lower: close * (1 + p.lowerPct),
                    horizonLabel: '@days hari'.trParams({
                      'days': '${p.horizonDays}',
                    }),
                    fiveDays: five == null ? null : MlCycle.reviseDay,
                    fiveUpper: five == null
                        ? null
                        : close * (1 + five.upperPct),
                    fiveLower: five == null
                        ? null
                        : close * (1 + five.lowerPct),
                    fiveLabel: '@days hari'.trParams({
                      'days': '${MlCycle.reviseDay}',
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (five != null) ...[
          _Eyebrow(
            '@n hari bursa · sampai @date'.trParams({
              'n': '${MlCycle.reviseDay}',
              'date': formatDayMonth(_tradingDay(window, MlCycle.reviseDay)),
            }),
          ),
          const SizedBox(height: 6),
          _BarrierTiles(
            upper: five.upperPct,
            lower: five.lowerPct,
            close: close,
          ),
          const SizedBox(height: 10),
          _Eyebrow(
            '@n hari bursa · sampai @date'.trParams({
              'n': '${p.horizonDays}',
              'date': formatDayMonth(_tradingDay(window, p.horizonDays)),
            }),
          ),
          const SizedBox(height: 6),
        ],
        _BarrierTiles(upper: p.upperPct, lower: p.lowerPct, close: close),
        const SizedBox(height: 8),
        Text(
          five == null ? _windowCaption(p, window) : _nestedCaption(p, window),
          style: AppText.body(size: 12, color: AppColors.ink2, height: 1.45),
        ),
        if (five == null) ...[
          const SizedBox(height: 8),
          Text(
            'Lebar batas mengikuti volatilitas @ticker 20 hari terakhir. Tidak ada jalur harga ke depan.'
                .trParams({'ticker': p.ticker}),
            style: AppText.body(size: 12, color: AppColors.mut, height: 1.45),
          ),
        ],
        if (wide && yearBarrier != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.warn),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${'Batas lebih lebar dari biasanya.'.tr} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warn,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Volatilitas 20 hari sedang @now% per hari. Dengan volatilitas setahun (@year%), batasnya sekitar @up dan @down.'
                            .trParams({
                              'now': formatIndicator(sd20 * 100, digits: 1),
                              'year': formatIndicator(sdYear * 100, digits: 1),
                              'up': _signed(yearBarrier.$1),
                              'down': _signed(yearBarrier.$2),
                            }),
                  ),
                ],
              ),
              style: AppText.body(
                size: 11.5,
                color: AppColors.ink2,
                height: 1.45,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Dua ubin batas atas dan bawah; harga rupiahnya ikut tampil bila harga
/// sinyal diketahui.
class _BarrierTiles extends StatelessWidget {
  const _BarrierTiles({
    required this.upper,
    required this.lower,
    required this.close,
  });

  final double upper;
  final double lower;
  final double? close;

  String _label(String text, double pct) {
    final c = close;
    return c == null
        ? text.tr
        : '${text.tr} · Rp ${formatPrice((c * (1 + pct)).round())}';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _PctTile(
          label: _label('Batas atas', upper),
          value: _signed(upper),
          color: AppColors.earn,
          soft: AppColors.earnSoft,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _PctTile(
          label: _label('Batas bawah', lower),
          value: _signed(lower),
          color: AppColors.spend,
          soft: AppColors.spendSoft,
        ),
      ),
    ],
  );
}

/// Hari bursa ke-[n] setelah sinyal: tanggal nyata bila sudah berjalan,
/// kalau belum diperkirakan dengan melompati Sabtu dan Minggu. Hari libur
/// bursa tidak diperhitungkan.
DateTime _tradingDay(PredictionWindow w, int n) {
  if (w.realized.length >= n) return w.realized[n - 1].date;
  var d = w.realized.isEmpty ? w.signalDate : w.realized.last.date;
  var left = n - w.realized.length;
  while (left > 0) {
    d = DateTime(d.year, d.month, d.day + 1);
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) left--;
  }
  return d;
}

/// Keterangan di bawah ubin bila batas 5 hari digambar di dalam batas 10 hari.
String _nestedCaption(MlPrediction p, PredictionWindow w) {
  final base =
      'Lebar batas mengikuti volatilitas @ticker 20 hari terakhir. Batas 5 hari sekitar 71% selebar batas 10 hari (akar dari 5/10), jadi selalu berada di dalamnya. Tidak ada jalur harga ke depan.'
          .trParams({'ticker': p.ticker});
  final tail = w.elapsed == 0
      ? 'Belum ada harga baru sesudah sinyal.'.tr
      : 'Garis hitam di dalam area adalah harga nyata sejauh ini.'.tr;
  return '$base $tail';
}

/// Kartu status siklus: hari yang sudah berjalan, revisi hari ke-5, dan hasil
/// nyata. Skor dan batas kedua jendela ada di kartu-kartu di atasnya. Prediksi
/// awal dan revisi ditampilkan terpisah; yang awal tidak pernah ditimpa.
class _CycleStatusCard extends StatelessWidget {
  const _CycleStatusCard({required this.cycle, required this.window});

  final MlCycle cycle;
  final PredictionWindow window;

  @override
  Widget build(BuildContext context) {
    final elapsed = cycle.isComplete
        ? MlCycle.horizonDays
        : math.min(window.elapsed, MlCycle.horizonDays);
    final five = cycle.fiveDay;
    final ten = cycle.tenDay;
    final hint = AppText.body(size: 12, color: AppColors.mut, height: 1.45);
    return _Panel(
      children: [
        _Eyebrow('Siklus 10 hari bursa'.tr),
        const SizedBox(height: 8),
        Text(
          'Sinyal @date · hari ke-@n dari @days'.trParams({
            'date': formatShortDate(cycle.cycleStart),
            'n': '$elapsed',
            'days': '${MlCycle.horizonDays}',
          }),
          style: AppText.body(size: 13, color: AppColors.ink2),
        ),
        const SizedBox(height: 10),
        _DayBar(elapsed: elapsed),
        if (five == null) ...[
          const SizedBox(height: 8),
          Text(
            'Model 5 hari belum aktif, jadi prediksi 5 hari tidak tampil.'.tr,
            style: hint,
          ),
        ],
        ..._revisionLines(elapsed, hint),
        if (five?.outcome != null || ten.outcome != null) ...[
          const SizedBox(height: 8),
          if (five?.outcome case final o?)
            ..._outcomeRows(o, MlCycle.reviseDay),
          if (ten.outcome case final o?)
            ..._outcomeRows(o, MlCycle.horizonDays),
        ] else ...[
          const SizedBox(height: 10),
          Text(
            'Hasil nyata 5 hari muncul @d5 dan 10 hari muncul @d10. Di hari ke-5, prediksi 10 hari direvisi satu kali dari jalur harga nyata; prediksi 5 hari tidak diulang.'
                .trParams({
                  'd5': formatDayMonth(_tradingDay(window, MlCycle.reviseDay)),
                  'd10': formatDayMonth(
                    _tradingDay(window, MlCycle.horizonDays),
                  ),
                }),
            style: hint,
          ),
        ],
      ],
    );
  }

  List<Widget> _outcomeRows(MlOutcome o, int days) => [
    _StatRow(
      label: 'Hasil nyata @days hari'.trParams({'days': '$days'}),
      value: _signed(o.retNet),
      color: _signColor(o.retNet),
      bold: true,
    ),
    if (o.hitUpper case final hit?)
      _StatRow(
        label: 'Batas atas tersentuh dalam @days hari'.trParams({
          'days': '$days',
        }),
        value: hit ? 'ya'.tr : 'tidak'.tr,
      ),
  ];

  List<Widget> _revisionLines(int elapsed, TextStyle hint) {
    final rev = cycle.revision;
    if (rev == null) {
      return [
        const SizedBox(height: 6),
        Text(
          elapsed < MlCycle.reviseDay
              ? 'Revisi tersedia setelah hari ke-5.'.tr
              : 'Revisi belum tersedia.'.tr,
          style: hint,
        ),
      ];
    }
    final text = switch (rev.state) {
      MlRevisionState.diperbarui =>
        'Dihitung ulang dari jalur harga 5 hari, bukan dari model yang belajar dari prediksi 5 hari. Prediksi awal tidak berubah.'
            .tr,
      MlRevisionState.atasTersentuh =>
        'Batas atas sudah tersentuh di hari 1 sampai 5, jadi hasil 10 hari sudah ditentukan.'
            .tr,
      MlRevisionState.bawahTersentuh =>
        'Batas bawah sudah tersentuh di hari 1 sampai 5, jadi hasil 10 hari sudah ditentukan.'
            .tr,
    };
    return [
      const SizedBox(height: 6),
      _StatRow(
        label: 'Revisi hari ke-5 (@date)'.trParams({
          'date': formatShortDate(rev.date),
        }),
        value: rev.state == MlRevisionState.diperbarui
            ? 'skor @score dari 100'.trParams({
                'score': '${_outOf100(rev.probUp)}',
              })
            : (rev.state == MlRevisionState.atasTersentuh
                  ? 'naik'.tr
                  : 'turun'.tr),
        bold: true,
      ),
      Text(text, style: hint),
    ];
  }
}

/// Sepuluh petak hari bursa; yang sudah berjalan terisi, dan garis bagi di
/// hari ke-5 menandai tempat revisi.
class _DayBar extends StatelessWidget {
  const _DayBar({required this.elapsed});

  final int elapsed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Hari ke-@n dari @days'.trParams({
      'n': '$elapsed',
      'days': '${MlCycle.horizonDays}',
    }),
    child: ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < MlCycle.horizonDays; i++) ...[
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i < elapsed ? AppColors.ink : AppColors.line2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < MlCycle.horizonDays - 1)
              SizedBox(width: i == MlCycle.reviseDay - 1 ? 10 : 3),
          ],
        ],
      ),
    ),
  );
}

/// Riwayat siklus sebelumnya: prediksi awal, revisi, dan hasil nyata tiap
/// siklus. Siklus baru dimulai setelah siklus lama selesai dan model dilatih
/// ulang.
class _CycleHistoryCard extends StatelessWidget {
  const _CycleHistoryCard({required this.cycles});

  final List<MlCycle> cycles;

  @override
  Widget build(BuildContext context) => _Panel(
    children: [
      _Eyebrow('Riwayat siklus'.tr),
      const SizedBox(height: 6),
      Text(
        'Siklus baru dimulai setelah siklus lama selesai dan model dilatih ulang tiap Sabtu. Prediksi awal dan revisi disimpan terpisah.'
            .tr,
        style: AppText.body(size: 12, color: AppColors.mut, height: 1.45),
      ),
      const SizedBox(height: 6),
      for (final c in cycles) _CycleRow(cycle: c),
    ],
  );
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.cycle});

  final MlCycle cycle;

  String _result(MlOutcome? o) => o == null ? 'berjalan'.tr : _signed(o.retNet);

  @override
  Widget build(BuildContext context) {
    final five = cycle.fiveDay;
    final ten = cycle.tenDay;
    final rev = cycle.revision;
    final outcome = ten.outcome;
    final revision = rev == null
        ? ''
        : ' ${'→ revisi @n'.trParams({'n': '${_outOf100(rev.probUp)}'})}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatShortDate(cycle.cycleStart),
                  style: AppText.mono(size: 12.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${'5 hari'.tr}: ${five == null ? '-' : _result(five.outcome)}'
                  ' · ${'10 hari'.tr}: ${'skor @n'.trParams({'n': '${_outOf100(ten.probUp)}'})}'
                  '$revision',
                  style: AppText.body(size: 11.5, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _result(outcome),
            style: AppText.mono(
              size: 12.5,
              weight: FontWeight.w700,
              color: outcome == null
                  ? AppColors.ink2
                  : _signColor(outcome.retNet),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kalimat jendela tetap prediksi: tanggal mulai, sudah berjalan berapa hari,
/// dan tanggal selesai bila sudah genap.
String _windowCaption(MlPrediction p, PredictionWindow w) {
  final params = {
    'date': formatShortDate(p.tradeDate),
    'days': '${p.horizonDays}',
    'n': '${w.elapsed}',
  };
  final end = w.endDate;
  if (end != null) {
    return 'Jendela tetap sejak sinyal @date selesai pada @end. Hasil nyata dihitung dari jendela ini.'
        .trParams({...params, 'end': formatShortDate(end)});
  }
  if (w.elapsed == 0) {
    return 'Jendela tetap sejak sinyal @date: @days hari bursa ke depan. Belum ada harga baru sesudah sinyal.'
        .trParams(params);
  }
  return 'Jendela tetap sejak sinyal @date: hari ke-@n dari @days hari bursa. Garis hitam di dalam area adalah harga nyata sejauh ini.'
      .trParams(params);
}

/// Kartu riwayat: prediksi-prediksi sebelumnya, masing-masing dengan jendela
/// tetap sejak tanggal sinyalnya. Prediksi baru tiap hari tidak menggantikan
/// yang lama, jadi hasil tiap sinyal bisa dibandingkan dengan harga nyata.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.current,
    required this.predictions,
    required this.history,
  });

  /// Prediksi yang sedang dibaca di kartu atas, tidak diulang di daftar.
  final MlPrediction current;
  final List<MlPrediction> predictions;
  final List<PricePoint> history;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final x in predictions)
        if (x.tradeDate != current.tradeDate) x,
    ];
    return _Panel(
      children: [
        _Eyebrow('Riwayat prediksi'.tr),
        const SizedBox(height: 6),
        Text(
          'Tiap hari ada prediksi baru dengan jendela @days hari bursa sendiri. Jendela yang lama tidak bergeser.'
              .trParams({'days': '${current.horizonDays}'}),
          style: AppText.body(size: 12, color: AppColors.mut, height: 1.45),
        ),
        const SizedBox(height: 6),
        for (final x in rows)
          _HistoryRow(prediction: x, window: PredictionWindow.of(x, history)),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.prediction, required this.window});

  final MlPrediction prediction;
  final PredictionWindow window;

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    final outcome = p.outcome;
    final String status;
    final Color color;
    if (outcome != null) {
      status = _signed(outcome.retNet);
      color = _signColor(outcome.retNet);
    } else if (window.elapsed == 0) {
      status = 'belum jalan'.tr;
      color = AppColors.mut;
    } else {
      status = 'hari ke-@n/@days'.trParams({
        'n': '${window.elapsed}',
        'days': '${p.horizonDays}',
      });
      color = AppColors.ink2;
    }
    final score = _outOf100(p.probUp);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatShortDate(p.tradeDate),
                  style: AppText.mono(size: 12.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_SignalStyle.of(p.signal).label} · $score',
                  style: AppText.body(size: 11.5, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: AppText.mono(
              size: 12.5,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PctTile extends StatelessWidget {
  const _PctTile({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final String label;
  final String value;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(size: 11, color: color)),
        Text(
          value,
          style: AppText.mono(size: 15, weight: FontWeight.w700, color: color),
        ),
      ],
    ),
  );
}

/// Garis harga sebulan, area 10 hari ke depan, dua garis batas putus-putus,
/// dan label harga di kanan.
class _BarrierChartPainter extends CustomPainter {
  const _BarrierChartPainter({
    required this.closes,
    required this.first,
    required this.last,
    required this.realized,
    required this.horizon,
    required this.windowEnd,
    required this.close,
    required this.upper,
    required this.lower,
    required this.horizonLabel,
    this.fiveDays,
    this.fiveUpper,
    this.fiveLower,
    this.fiveLabel = '',
  });

  final List<double> closes;
  final DateTime first;
  final DateTime last;

  /// Harga penutupan nyata sesudah hari sinyal di dalam jendela, terlama
  /// dulu. Kosong selama belum ada hari yang berjalan.
  final List<double> realized;

  /// Panjang jendela dalam hari bursa.
  final int horizon;

  /// Hari terakhir jendela, null selama jendela belum genap.
  final DateTime? windowEnd;
  final double close;
  final double upper;
  final double lower;
  final String horizonLabel;

  /// Hari ke-berapa batas 5 hari berakhir di dalam jendela, null bila tidak
  /// ada prediksi 5 hari. Tiga isian berikutnya hanya berlaku bila ada.
  final int? fiveDays;
  final double? fiveUpper;
  final double? fiveLower;
  final String fiveLabel;

  static const _tagWidth = 56.0;
  static const _bottom = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotRight = size.width - _tagWidth - 4;
    final lineRight = plotRight * 0.78;
    var lo = math.min(lower, closes.reduce(math.min));
    var hi = math.max(upper, closes.reduce(math.max));
    for (final value in realized) {
      lo = math.min(lo, value);
      hi = math.max(hi, value);
    }
    final pad = (hi - lo) * 0.06;
    lo -= pad;
    hi += pad;
    final h = size.height - _bottom;
    double y(double v) => (hi - v) / (hi - lo) * h;
    double x(int i) =>
        closes.length == 1 ? 0 : i / (closes.length - 1) * lineRight;

    final lastX = x(closes.length - 1);
    final fiveEnd = fiveDays;
    final fiveUp = fiveUpper;
    final fiveLow = fiveLower;
    final nested =
        fiveEnd != null && fiveUp != null && fiveLow != null && horizon > 0;
    // Hari ke-5 jatuh di 5/horizon lebar area, sama dengan garis nyata.
    final midX = nested ? lastX + (plotRight - lastX) * fiveEnd / horizon : 0.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(lastX, y(upper), plotRight, y(lower)),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.paper2.withValues(alpha: 0.7),
    );
    if (nested) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(lastX, y(fiveUp), midX, y(fiveLow)),
          const Radius.circular(2),
        ),
        Paint()..color = AppColors.line.withValues(alpha: 0.75),
      );
    }
    final path = Path();
    for (var i = 0; i < closes.length; i++) {
      final point = Offset(x(i), y(closes[i]));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    if (realized.isNotEmpty && horizon > 0) {
      // Hari ke-k jendela jatuh di k/horizon lebar area, jadi garis nyata
      // mengisi area dari kiri dan jendela yang belum genap tetap terlihat.
      final step = (plotRight - lastX) / horizon;
      final realPath = Path()..moveTo(lastX, y(close));
      for (var k = 0; k < realized.length; k++) {
        realPath.lineTo(lastX + step * (k + 1), y(realized[k]));
      }
      canvas.drawPath(
        realPath,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(
        Offset(lastX + step * realized.length, y(realized.last)),
        3,
        Paint()..color = AppColors.ink,
      );
    }
    for (final (value, color) in [
      (upper, AppColors.earn),
      (lower, AppColors.spend),
    ]) {
      paintDashedLine(
        canvas,
        Offset(lastX, y(value)),
        Offset(plotRight, y(value)),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
    }
    if (nested) {
      for (final (value, color) in [
        (fiveUp, AppColors.earn),
        (fiveLow, AppColors.spend),
      ]) {
        paintDashedLine(
          canvas,
          Offset(lastX, y(value)),
          Offset(midX, y(value)),
          Paint()
            ..color = color
            ..strokeWidth = 2,
          dash: 2,
          gap: 2,
        );
      }
      paintDashedLine(
        canvas,
        Offset(midX, y(upper)),
        Offset(midX, y(lower)),
        Paint()
          ..color = AppColors.mut
          ..strokeWidth = 1,
        dash: 2,
        gap: 3,
      );
    }
    canvas.drawCircle(
      Offset(lastX, y(close)),
      4.5,
      Paint()..color = AppColors.ink,
    );
    canvas.drawCircle(
      Offset(lastX, y(close)),
      4.5,
      Paint()
        ..color = AppColors.card
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (nested) {
      for (final (value, color) in [
        (fiveUp, AppColors.earn),
        (fiveLow, AppColors.spend),
      ]) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(midX + 1.5, y(value) - 7, 28, 14),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.85));
        final text = TextPainter(
          text: TextSpan(
            text: formatPrice(value.round()),
            style: AppText.mono(
              size: 8.5,
              weight: FontWeight.w600,
              color: AppColors.paper,
              letterSpacing: 0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset(rect.left + (28 - text.width) / 2, y(value) - text.height / 2),
        );
      }
    }
    for (final (value, color) in [
      (upper, AppColors.earn),
      (lower, AppColors.spend),
      (close, AppColors.ink),
    ]) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(plotRight + 4, y(value) - 9, _tagWidth, 18),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      final text = TextPainter(
        text: TextSpan(
          text: formatPrice(value.round()),
          style: AppText.mono(
            size: 10.5,
            weight: FontWeight.w600,
            color: AppColors.paper,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(
          rect.left + (_tagWidth - text.width) / 2,
          y(value) - text.height / 2,
        ),
      );
    }
    paintText(canvas, formatDayMonth(first), Offset(0, h + 9));
    final lastText = TextPainter(
      text: TextSpan(
        text: formatDayMonth(last),
        style: AppText.mono(size: 9.5, color: AppColors.mut),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lastText.paint(canvas, Offset(lastX - lastText.width / 2, h + 3));
    final end = windowEnd;
    if (nested) {
      for (final (label, dx) in [('H+5', midX), ('H+10', plotRight)]) {
        final t = TextPainter(
          text: TextSpan(
            text: label,
            style: AppText.mono(size: 9, color: AppColors.mut),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        t.paint(canvas, Offset(dx - t.width / 2, h + 3));
      }
    } else if (end != null) {
      final endText = TextPainter(
        text: TextSpan(
          text: formatDayMonth(end),
          style: AppText.mono(size: 9.5, color: AppColors.mut),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      endText.paint(canvas, Offset(plotRight - endText.width, h + 3));
    }
    final zone = TextPainter(
      text: TextSpan(
        text: horizonLabel,
        style: AppText.body(size: 9, color: AppColors.mut),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Dengan kotak 5 hari, label 10 hari pindah ke separuh kanan supaya tidak
    // bertumpuk dengan label 5 hari di separuh kiri.
    final zoneCenter = nested
        ? (midX + plotRight) / 2
        : (lastX + plotRight) / 2;
    zone.paint(canvas, Offset(zoneCenter - zone.width / 2, y(upper) + 4));
    if (nested) {
      final five = TextPainter(
        text: TextSpan(
          text: fiveLabel,
          style: AppText.body(
            size: 9,
            weight: FontWeight.w700,
            color: AppColors.ink2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      five.paint(
        canvas,
        Offset((lastX + midX) / 2 - five.width / 2, y(fiveUp) + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_BarrierChartPainter old) =>
      !identical(old.closes, closes) ||
      !identical(old.realized, realized) ||
      old.windowEnd != windowEnd ||
      old.upper != upper ||
      old.lower != lower ||
      old.fiveUpper != fiveUpper ||
      old.fiveLower != fiveLower ||
      old.close != close;
}

/// Kartu 3: faktor dengan sumbangan terbesar ke skor. Dengan faktor 5 hari,
/// tiap baris punya dua tanda berdampingan, 10 hari dan 5 hari; fitur di luar
/// empat terbesar suatu model diberi tanda "kecil" di kolom model itu.
class _FactorsCard extends StatelessWidget {
  const _FactorsCard({
    required this.ten,
    required this.five,
    required this.hasFiveDay,
  });

  /// Empat faktor terbesar model 10 hari.
  final List<MlDriver> ten;

  /// Semua faktor model 5 hari, terbesar dulu. Kosong bila belum tersimpan.
  final List<MlDriver> five;

  /// True bila siklus punya prediksi 5 hari, walau faktornya belum ada.
  final bool hasFiveDay;

  static const _chipWidth = 58.0;

  @override
  Widget build(BuildContext context) {
    final fiveTop = five.take(_topFactors).toList();
    final showFive = fiveTop.isNotEmpty;
    final rows = <String>[
      for (final d in ten) d.feature,
      for (final d in fiveTop)
        if (!ten.any((t) => t.feature == d.feature)) d.feature,
    ];
    MlDriver? find(List<MlDriver> list, String feature) {
      for (final d in list) {
        if (d.feature == feature) return d;
      }
      return null;
    }

    Widget cell(List<MlDriver> top, String feature) {
      final d = find(top, feature);
      return SizedBox(
        width: _chipWidth,
        child: d == null ? const _FactorChip.small() : _FactorChip(driver: d),
      );
    }

    final headStyle = AppText.body(
      size: 10.5,
      weight: FontWeight.w700,
      color: AppColors.mut,
    );
    return _Panel(
      children: [
        _Eyebrow('Yang memengaruhi skor'.tr),
        if (showFive) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (ten.isNotEmpty)
                SizedBox(
                  width: _chipWidth,
                  child: Text(
                    '10 hari'.tr,
                    textAlign: TextAlign.center,
                    style: headStyle,
                  ),
                ),
              if (ten.isNotEmpty) const SizedBox(width: 6),
              SizedBox(
                width: _chipWidth,
                child: Text(
                  '5 hari'.tr,
                  textAlign: TextAlign.center,
                  style: headStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ] else
          const SizedBox(height: 8),
        for (final feature in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_featureLabels[feature] ?? feature).tr,
                        style: AppText.body(size: 13, weight: FontWeight.w700),
                      ),
                      if (_driverMeaning(
                            find(ten, feature) ?? find(five, feature),
                          )
                          case final String meaning)
                        Text(
                          meaning,
                          style: AppText.body(size: 11.5, color: AppColors.mut),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (ten.isNotEmpty) cell(ten, feature),
                if (ten.isNotEmpty && showFive) const SizedBox(width: 6),
                if (showFive) cell(fiveTop, feature),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          showFive && ten.isNotEmpty
              ? '+ menaikkan skor, − menurunkannya. "Kecil" berarti pengaruhnya di luar empat terbesar milik model itu. Ini penjelasan skor, bukan alasan harga bergerak.'
                    .tr
              : 'Menjelaskan skor model, bukan alasan harga bergerak.'.tr,
          style: AppText.body(size: 11.5, color: AppColors.mut, height: 1.45),
        ),
        if (hasFiveDay && !showFive) ...[
          const SizedBox(height: 4),
          Text(
            'Faktor 5 hari belum tersimpan, jadi hanya faktor 10 hari yang tampil.'
                .tr,
            style: AppText.body(size: 11.5, color: AppColors.mut, height: 1.45),
          ),
        ],
      ],
    );
  }
}

/// Tanda + skor, − skor, atau "kecil" untuk satu model pada satu faktor.
class _FactorChip extends StatelessWidget {
  const _FactorChip({required this.driver}) : small = false;

  const _FactorChip.small() : driver = null, small = true;

  final MlDriver? driver;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final d = driver;
    final up = d?.pushesUp ?? false;
    final color = small
        ? AppColors.mut
        : up
        ? AppColors.earn
        : AppColors.spend;
    final soft = small
        ? AppColors.paper2
        : up
        ? AppColors.earnSoft
        : AppColors.spendSoft;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        (small
                ? 'kecil'
                : up
                ? '+ skor'
                : '− skor')
            .tr,
        style: AppText.body(size: 11, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Hasil nyata prediksi lama: label waktu itu, harga awal dan akhir uji, dan
/// hasil bersih setelah biaya.
class _OutcomePanel extends StatelessWidget {
  const _OutcomePanel({required this.prediction, required this.outcome});

  final MlPrediction prediction;
  final MlOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    final entry = o.entry;
    final exit = o.exit;
    final hit = o.hitUpper;
    return _Panel(
      children: [
        _PanelTitle(
          '${'Hasil nyata prediksi'.tr} ${formatShortDate(prediction.tradeDate)}',
        ),
        const SizedBox(height: 10),
        _SignalChip(style: _SignalStyle.of(prediction.signal)),
        const SizedBox(height: 8),
        if (entry != null && exit != null)
          _StatRow(
            label: 'Harga awal dan akhir'.tr,
            value:
                '${formatPrice(entry.round())} → ${formatPrice(exit.round())}',
          ),
        _StatRow(
          label: 'Hasil bersih'.tr,
          value: _signed(o.retNet),
          color: _signColor(o.retNet),
          bold: true,
        ),
        if (hit != null)
          _StatRow(
            label: 'Menyentuh batas atas'.tr,
            value: hit ? 'ya'.tr : 'tidak'.tr,
          ),
        const SizedBox(height: 6),
        Text(
          '${'Dihitung pada'.tr} ${formatShortDate(o.date)}.',
          style: AppText.body(size: 12, color: AppColors.ink2),
        ),
      ],
    );
  }
}

/// Satu baris label dengan satu nilai rata kanan.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.color = AppColors.ink,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.body(
              size: 12.5,
              weight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: AppText.mono(
            size: 12.5,
            weight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

/// Label, kalimat, dan warna tiap sinyal. Kalimatnya membandingkan skor
/// dengan rata-rata, tanpa kata naik, beli, atau jual.
class _SignalStyle {
  const _SignalStyle(
    this.label,
    this.headline,
    this.detail,
    this.color,
    this.soft,
  );

  final String label;

  /// Kunci terjemahan dengan @ticker.
  final String headline;

  /// Kunci terjemahan kalimat kedua.
  final String detail;
  final Color color;
  final Color soft;

  static _SignalStyle of(MlSignal signal) => switch (signal) {
    MlSignal.peluang => _SignalStyle(
      'Skor di atas rata-rata'.tr,
      'Skor @ticker di atas rata-rata saham lain.',
      'Model memberi skor lebih tinggi dari biasanya untuk data pada hari sinyal.',
      AppColors.earn,
      AppColors.earnSoft,
    ),
    MlSignal.netral => _SignalStyle(
      'Skor sekitar rata-rata'.tr,
      'Skor @ticker hampir sama dengan rata-rata saham lain.',
      'Model tidak melihat keunggulan teknikal khusus pada data hari sinyal.',
      AppColors.ink2,
      AppColors.paper2,
    ),
    MlSignal.risiko => _SignalStyle(
      'Skor di bawah rata-rata'.tr,
      'Skor @ticker di bawah rata-rata saham lain.',
      'Model memberi skor lebih rendah dari biasanya untuk data pada hari sinyal.',
      AppColors.spend,
      AppColors.spendSoft,
    ),
  };
}
