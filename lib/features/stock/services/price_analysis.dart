import 'dart:math' as math;

import '../models/daily_bar.dart';
import '../models/price_point.dart';
import 'technical_reading.dart';

/// Arah tren dari posisi harga terhadap MA50 dan MA200. Ini kondisi hari
/// ini, bukan prediksi arah.
enum TrendKind {
  /// Harga di atas MA50 dan MA50 di atas MA200.
  naik,

  /// Harga di bawah MA50 dan MA50 di bawah MA200.
  turun,

  /// Selain dua di atas, misalnya harga di bawah MA50 tetapi MA50 masih di
  /// atas MA200. "Sideways" sungguhan butuh uji rentang, jadi tidak dipakai.
  campuran,
}

/// Rata-rata [n] nilai terakhir, null bila datanya kurang.
double? smaLast(List<double> values, int n) {
  if (n <= 0 || values.length < n) return null;
  var sum = 0.0;
  for (var i = values.length - n; i < values.length; i++) {
    sum += values[i];
  }
  return sum / n;
}

/// Rata-rata bergerak [n] hari untuk tiap posisi; null sebelum cukup data.
List<double?> smaSeries(List<double> values, int n) {
  final out = List<double?>.filled(values.length, null);
  var sum = 0.0;
  for (var i = 0; i < values.length; i++) {
    sum += values[i];
    if (i >= n) sum -= values[i - n];
    if (i >= n - 1) out[i] = sum / n;
  }
  return out;
}

/// Pita bawah Bollinger 20 hari (2 simpangan baku populasi) per posisi.
List<double?> bollingerLower(List<double> closes, {int n = 20, double k = 2}) {
  final out = List<double?>.filled(closes.length, null);
  for (var i = n - 1; i < closes.length; i++) {
    var sum = 0.0;
    for (var j = i - n + 1; j <= i; j++) {
      sum += closes[j];
    }
    final mean = sum / n;
    var sq = 0.0;
    for (var j = i - n + 1; j <= i; j++) {
      sq += (closes[j] - mean) * (closes[j] - mean);
    }
    out[i] = mean - k * math.sqrt(sq / n);
  }
  return out;
}

/// RSI Wilder [n] hari per posisi (0 sampai 100), null sebelum cukup data.
List<double?> rsiSeries(List<double> closes, {int n = 14}) {
  final out = List<double?>.filled(closes.length, null);
  if (closes.length <= n) return out;
  var gain = 0.0;
  var loss = 0.0;
  for (var i = 1; i <= n; i++) {
    final d = closes[i] - closes[i - 1];
    if (d > 0) {
      gain += d;
    } else {
      loss -= d;
    }
  }
  gain /= n;
  loss /= n;
  double rsi(double g, double l) => l == 0 ? 100 : 100 - 100 / (1 + g / l);
  out[n] = rsi(gain, loss);
  for (var i = n + 1; i < closes.length; i++) {
    final d = closes[i] - closes[i - 1];
    gain = (gain * (n - 1) + (d > 0 ? d : 0)) / n;
    loss = (loss * (n - 1) + (d < 0 ? -d : 0)) / n;
    out[i] = rsi(gain, loss);
  }
  return out;
}

/// Tren dan rata-rata yang dipakai untuk menentukannya.
class TrendFacts {
  const TrendFacts({
    required this.kind,
    required this.close,
    required this.ma50,
    required this.ma200,
    this.ma20,
  });

  final TrendKind kind;
  final double close;
  final double? ma20;
  final double ma50;
  final double ma200;
}

/// Null bila riwayat kurang dari 200 hari bursa.
TrendFacts? trendFacts(List<PricePoint> oldestFirst) {
  final closes = [for (final p in oldestFirst) p.close];
  final ma50 = smaLast(closes, 50);
  final ma200 = smaLast(closes, 200);
  if (ma50 == null || ma200 == null) return null;
  final close = closes.last;
  final kind = close > ma50 && ma50 > ma200
      ? TrendKind.naik
      : close < ma50 && ma50 < ma200
      ? TrendKind.turun
      : TrendKind.campuran;
  return TrendFacts(
    kind: kind,
    close: close,
    ma20: smaLast(closes, 20),
    ma50: ma50,
    ma200: ma200,
  );
}

/// Rentang harga yang beberapa kali menjadi titik balik.
class PriceZone {
  const PriceZone({required this.low, required this.high, required this.dates});

  final double low;
  final double high;

  /// Tanggal titik balik yang membentuk zona, terlama dulu.
  final List<DateTime> dates;
}

class SupportResistance {
  const SupportResistance({this.support, this.resistance});

  final PriceZone? support;
  final PriceZone? resistance;
}

/// Titik balik sederhana: terendah (atau tertinggi) di antara [span] hari di
/// kiri dan kanannya. Hari terakhir butuh paling tidak satu hari di kanan.
List<int> _pivots(List<double> values, int span, {required bool low}) {
  final out = <int>[];
  for (var i = 1; i < values.length - 1; i++) {
    var ok = true;
    for (
      var j = math.max(0, i - span);
      j <= math.min(values.length - 1, i + span);
      j++
    ) {
      if (j == i) continue;
      if (low ? values[j] < values[i] : values[j] > values[i]) {
        ok = false;
        break;
      }
    }
    if (ok) out.add(i);
  }
  return out;
}

/// Support dan resistance otomatis dari titik balik [window] hari terakhir.
/// Support = titik terendah terdekat di bawah harga, digabung dengan titik
/// lain yang selisihnya di bawah [merge]. Resistance sebaliknya. Ini
/// perkiraan kasar dan bisa keliru.
SupportResistance findSupportResistance(
  List<PricePoint> oldestFirst, {
  int window = 60,
  int span = 3,
  double merge = 0.015,
}) {
  if (oldestFirst.length < 10) return const SupportResistance();
  final recent = oldestFirst.length > window
      ? oldestFirst.sublist(oldestFirst.length - window)
      : oldestFirst;
  final close = recent.last.close;
  final lows = [for (final p in recent) p.lowOrClose];
  final highs = [for (final p in recent) p.highOrClose];

  PriceZone? zone(List<int> idx, List<double> values, {required bool below}) {
    final candidates = [
      for (final i in idx)
        if (below ? values[i] < close : values[i] > close) i,
    ];
    if (candidates.isEmpty) return null;
    candidates.sort(
      (a, b) => below
          ? values[b].compareTo(values[a])
          : values[a].compareTo(values[b]),
    );
    final anchor = values[candidates.first];
    final members = [
      for (final i in candidates)
        if ((values[i] - anchor).abs() / anchor <= merge) i,
    ]..sort();
    final picked = [for (final i in members) values[i]];
    return PriceZone(
      low: picked.reduce(math.min),
      high: picked.reduce(math.max),
      dates: [for (final i in members) recent[i].date],
    );
  }

  return SupportResistance(
    support: zone(_pivots(lows, span, low: true), lows, below: true),
    resistance: zone(_pivots(highs, span, low: false), highs, below: false),
  );
}

/// Posisi harga terakhir di rentang [window] hari: 0 = terendah, 1 = tertinggi.
class RangePosition {
  const RangePosition({
    required this.low,
    required this.high,
    required this.fraction,
  });

  final double low;
  final double high;
  final double fraction;
}

RangePosition? rangePosition(List<PricePoint> oldestFirst, {int window = 60}) {
  if (oldestFirst.isEmpty) return null;
  final recent = oldestFirst.length > window
      ? oldestFirst.sublist(oldestFirst.length - window)
      : oldestFirst;
  final low = recent.map((p) => p.lowOrClose).reduce(math.min);
  final high = recent.map((p) => p.highOrClose).reduce(math.max);
  if (high <= low) return null;
  return RangePosition(
    low: low,
    high: high,
    fraction: ((recent.last.close - low) / (high - low)).clamp(0.0, 1.0),
  );
}

/// Divergence kasar antara harga dan RSI 14 pada dua titik terendah terakhir.
class Divergence {
  const Divergence({
    required this.firstDate,
    required this.firstPrice,
    required this.firstRsi,
    required this.secondDate,
    required this.secondPrice,
    required this.secondRsi,
  });

  final DateTime firstDate;
  final double firstPrice;
  final double firstRsi;
  final DateTime secondDate;
  final double secondPrice;
  final double secondRsi;
}

/// Harga membuat titik terendah lebih rendah, tetapi RSI tidak. Dicari di
/// [window] hari terakhir. Null bila tidak ada. Deteksi kasar, sering palsu.
Divergence? findLowDivergence(List<PricePoint> oldestFirst, {int window = 20}) {
  if (oldestFirst.length < 40) return null;
  final closes = [for (final p in oldestFirst) p.close];
  final rsi = rsiSeries(closes);
  final start = oldestFirst.length - window;
  final lows = [for (final p in oldestFirst) p.lowOrClose];
  final pivots = [
    for (final i in _pivots(lows, 2, low: true))
      if (i >= start && rsi[i] != null) i,
  ];
  if (pivots.length < 2) return null;
  final a = pivots[pivots.length - 2];
  final b = pivots.last;
  if (!(lows[b] < lows[a] && rsi[b]! > rsi[a]!)) return null;
  return Divergence(
    firstDate: oldestFirst[a].date,
    firstPrice: lows[a],
    firstRsi: rsi[a]!,
    secondDate: oldestFirst[b].date,
    secondPrice: lows[b],
    secondRsi: rsi[b]!,
  );
}

/// Simpangan baku harian log return [n] hari terakhir, null bila kurang.
double? dailyVolatility(List<PricePoint> oldestFirst, int n) {
  if (oldestFirst.length < n + 1) return null;
  final r = <double>[
    for (var i = oldestFirst.length - n; i < oldestFirst.length; i++)
      math.log(oldestFirst[i].close / oldestFirst[i - 1].close),
  ];
  final mean = r.reduce((a, b) => a + b) / r.length;
  var sq = 0.0;
  for (final x in r) {
    sq += (x - mean) * (x - mean);
  }
  return math.sqrt(sq / (r.length - 1));
}

/// Batas atas dan bawah gaya model: exp(±sd·√h) − 1, sebagai pecahan.
(double, double) barrierFromVolatility(double sd, int horizon) {
  final w = sd * math.sqrt(horizon.toDouble());
  return (math.exp(w) - 1, math.exp(-w) - 1);
}

/// Sentimen pasar dari IHSG: posisi terhadap MA50 dan MA200.
enum MarketMood { kuat, netral, lemah }

class MarketSentiment {
  const MarketSentiment({
    required this.mood,
    required this.close,
    required this.change20,
    required this.date,
  });

  final MarketMood mood;
  final double close;

  /// Perubahan 20 hari bursa terakhir, pecahan.
  final double change20;
  final DateTime date;
}

MarketSentiment? marketSentiment(List<PricePoint> indexOldestFirst) {
  final facts = trendFacts(indexOldestFirst);
  if (facts == null || indexOldestFirst.length < 21) return null;
  final mood = facts.close > facts.ma50 && facts.close > facts.ma200
      ? MarketMood.kuat
      : facts.close < facts.ma50 && facts.close < facts.ma200
      ? MarketMood.lemah
      : MarketMood.netral;
  final past = indexOldestFirst[indexOldestFirst.length - 21].close;
  return MarketSentiment(
    mood: mood,
    close: facts.close,
    change20: facts.close / past - 1,
    date: indexOldestFirst.last.date,
  );
}

/// Hari dengan volume terbesar di [bars], null bila volume kosong semua.
DailyBar? biggestVolumeDay(List<DailyBar> bars) {
  DailyBar? best;
  for (final bar in bars) {
    final v = bar.volumeLot;
    if (v == null) continue;
    if (best == null || v > best.volumeLot!) best = bar;
  }
  return best;
}

/// Berapa hari berturut-turut sebuah deret naik (atau turun) sampai hari
/// terakhir, beserta nilai dan tanggal awalnya.
class Streak {
  const Streak({
    required this.days,
    required this.rising,
    required this.fromValue,
    required this.fromDate,
  });

  final int days;
  final bool rising;
  final double fromValue;
  final DateTime fromDate;
}

/// Streak garis K (stochA) di akhir [bars]. Null bila datanya kurang.
Streak? stochKStreak(List<DailyBar> bars) {
  final points = [
    for (final bar in bars)
      if (bar.stochA != null) (bar.tradeDate, bar.stochA!),
  ];
  if (points.length < 2) return null;
  final last = points.length - 1;
  final rising = points[last].$2 > points[last - 1].$2;
  var start = last;
  while (start > 0 &&
      (rising
          ? points[start].$2 > points[start - 1].$2
          : points[start].$2 < points[start - 1].$2)) {
    start--;
  }
  return Streak(
    days: last - start,
    rising: rising,
    fromValue: points[start].$2,
    fromDate: points[start].$1,
  );
}

/// Berapa hari terakhir histogram MACD berturut-turut memudar (mengecil)
/// atau memekat (membesar), dan tanggal hari pertamanya.
class HistStreak {
  const HistStreak({
    required this.days,
    required this.fading,
    required this.since,
  });

  final int days;
  final bool fading;
  final DateTime since;
}

HistStreak? macdHistStreak(List<DailyBar> bars) {
  final trends = <(DateTime, HistTrend)>[];
  for (var i = 1; i < bars.length; i++) {
    final t = TechnicalReading.histTrend(
      bars[i].macdHist,
      bars[i - 1].macdHist,
    );
    if (t == null) continue;
    trends.add((bars[i].tradeDate, t));
  }
  if (trends.isEmpty) return null;
  final kind = trends.last.$2;
  var i = trends.length - 1;
  while (i > 0 && trends[i - 1].$2 == kind) {
    i--;
  }
  return HistStreak(
    days: trends.length - i,
    fading: kind == HistTrend.shrinking,
    since: trends[i].$1,
  );
}

/// Rata-rata bergerak [n] hari dari [history], disejajarkan dengan tanggal
/// [bars]. Hari yang tidak ada di riwayat bernilai null.
List<double?> alignedSma(List<PricePoint> history, List<DailyBar> bars, int n) {
  final closes = [for (final p in history) p.close];
  final series = smaSeries(closes, n);
  final byDate = <DateTime, double?>{
    for (var i = 0; i < history.length; i++) _day(history[i].date): series[i],
  };
  return [for (final bar in bars) byDate[_day(bar.tradeDate)]];
}

/// Pita bawah Bollinger 20 hari, disejajarkan dengan tanggal [bars].
List<double?> alignedBollingerLower(
  List<PricePoint> history,
  List<DailyBar> bars,
) {
  final series = bollingerLower([for (final p in history) p.close]);
  final byDate = <DateTime, double?>{
    for (var i = 0; i < history.length; i++) _day(history[i].date): series[i],
  };
  return [for (final bar in bars) byDate[_day(bar.tradeDate)]];
}

/// RSI 14 dari [history], disejajarkan dengan tanggal [bars].
List<double?> alignedRsi(List<PricePoint> history, List<DailyBar> bars) {
  final series = rsiSeries([for (final p in history) p.close]);
  final byDate = <DateTime, double?>{
    for (var i = 0; i < history.length; i++) _day(history[i].date): series[i],
  };
  return [for (final bar in bars) byDate[_day(bar.tradeDate)]];
}

/// Perubahan dari penutupan terakhir sebulan kalender sebelum hari terakhir
/// sampai hari terakhir, pecahan. Null bila riwayat tidak sampai sebulan.
(double, DateTime)? monthChange(List<PricePoint> oldestFirst) {
  final last = oldestFirst.lastOrNull;
  if (last == null) return null;
  final d = last.date;
  final monthEnd = DateTime(d.year, d.month, 0).day;
  final cutoff = DateTime(d.year, d.month - 1, math.min(d.day, monthEnd));
  final base = oldestFirst.lastWhere(
    (p) => !_day(p.date).isAfter(cutoff),
    orElse: () => last,
  );
  if (identical(base, last)) return null;
  return (last.close / base.close - 1, base.date);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
