import 'dart:math' as math;

import '../models/price_point.dart';

// Port dari kode lab `supabase/functions/market-ml/scen.ts` dan `patterns.ts`
// (branch claude/stock-ml-pipeline). Definisi dan ambang sama dengan yang
// dipakai di uji skenario dan uji detektor pola 1 November 2026. Semuanya
// deskriptif: di uji 107 saham tidak ada yang terbukti memprediksi 10 hari.

/// Tren versi katalog: UP bila harga > MA50 > MA200 dan MA50 naik dibanding
/// 10 hari lalu, DOWN kebalikannya, selain itu SIDE.
enum ScanTrend { up, down, side }

/// Pola candlestick yang dicari pada bar terakhir.
enum CandlePattern {
  hammer,
  bullishEngulfing,
  piercing,
  morningStar,
  bullishHarami,
  shootingStar,
  bearishEngulfing,
  darkCloud,
  eveningStar,
  bearishHarami,
}

/// Jenis pola chart besar dari detektor zigzag.
enum ChartPatternKind {
  doubleBottom,
  doubleTop,
  headShoulders,
  inverseHeadShoulders,
  ascendingUp,
  ascendingDown,
  descendingUp,
  descendingDown,
  symmetricUp,
  symmetricDown,
  bullFlag,
  bearFlag,
}

/// Satu deteksi pola chart: [breakout] tanggal harga menembus, [keyDates]
/// tanggal titik kunci (lembah, puncak, bahu, dan seterusnya).
class ChartPatternEvent {
  const ChartPatternEvent({
    required this.kind,
    required this.breakout,
    required this.keyDates,
  });

  final ChartPatternKind kind;
  final DateTime breakout;
  final List<DateTime> keyDates;
}

/// Berapa syarat skenario katalog yang terpenuhi pada bar terakhir.
class ScenarioCheck {
  const ScenarioCheck({
    required this.code,
    required this.met,
    required this.total,
  });

  final String code;
  final int met;
  final int total;

  bool get active => met == total;
}

List<double?> _rma(List<double?> vals, int len) {
  final out = List<double?>.filled(vals.length, null);
  double? s;
  final buf = <double>[];
  for (var i = 0; i < vals.length; i++) {
    final v = vals[i];
    if (v == null) continue;
    if (s == null) {
      buf.add(v);
      if (buf.length == len) {
        s = buf.reduce((a, b) => a + b) / len;
        out[i] = s;
      }
    } else {
      s = (s * (len - 1) + v) / len;
      out[i] = s;
    }
  }
  return out;
}

List<double?> _ema(List<double?> vals, int len) {
  final out = List<double?>.filled(vals.length, null);
  final a = 2 / (len + 1);
  double? s;
  final buf = <double>[];
  for (var i = 0; i < vals.length; i++) {
    final v = vals[i];
    if (v == null) continue;
    if (s == null) {
      buf.add(v);
      if (buf.length == len) {
        s = buf.reduce((x, y) => x + y) / len;
        out[i] = s;
      }
    } else {
      s = a * v + (1 - a) * s;
      out[i] = s;
    }
  }
  return out;
}

List<double?> _sma(List<double?> v, int len) {
  final out = List<double?>.filled(v.length, null);
  var sum = 0.0;
  var nulls = 0;
  for (var i = 0; i < v.length; i++) {
    final x = v[i];
    if (x == null) {
      nulls++;
    } else {
      sum += x;
    }
    if (i >= len) {
      final y = v[i - len];
      if (y == null) {
        nulls--;
      } else {
        sum -= y;
      }
    }
    if (i >= len - 1 && nulls == 0) out[i] = sum / len;
  }
  return out;
}

/// Fraksi harga IDX, sama dengan kode lab.
double _tick(double p) => p < 200
    ? 1
    : p < 500
    ? 2
    : p < 2000
    ? 5
    : p < 5000
    ? 10
    : 25;

/// Deret indikator untuk satu saham, urut dari yang terlama.
class TechnicalScan {
  TechnicalScan(this.history)
    : n = history.length,
      o = [for (final p in history) p.open ?? p.close],
      h = [for (final p in history) p.highOrClose],
      l = [for (final p in history) p.lowOrClose],
      c = [for (final p in history) p.close] {
    final v = <double?>[for (final p in history) p.volume ?? 0];
    final ch = <double?>[
      for (var i = 0; i < n; i++) i == 0 ? null : c[i] - c[i - 1],
    ];
    final g = _rma([for (final x in ch) x == null ? null : math.max(x, 0)], 14);
    final d = _rma([
      for (final x in ch) x == null ? null : math.max(-x, 0),
    ], 14);
    rsi = [
      for (var i = 0; i < n; i++)
        g[i] == null || d[i] == null
            ? null
            : d[i] == 0
            ? 100
            : 100 - 100 / (1 + g[i]! / d[i]!),
    ];
    final st = List<double?>.filled(n, null);
    for (var i = 13; i < n; i++) {
      var lo = double.infinity;
      var hi = double.negativeInfinity;
      var ok = true;
      for (var j = i - 13; j <= i; j++) {
        final r = rsi[j];
        if (r == null) {
          ok = false;
          break;
        }
        lo = math.min(lo, r);
        hi = math.max(hi, r);
      }
      if (ok) st[i] = hi == lo ? 0 : (rsi[i]! - lo) / (hi - lo) * 100;
    }
    srK = _sma(st, 3);
    srD = _sma(srK, 3);
    final e12 = _ema(c, 12);
    final e26 = _ema(c, 26);
    macd = [
      for (var i = 0; i < n; i++) e26[i] == null ? null : e12[i]! - e26[i]!,
    ];
    sig = _ema(macd, 9);
    final tr = <double?>[
      for (var i = 0; i < n; i++)
        i == 0
            ? h[i] - l[i]
            : math.max(
                h[i] - l[i],
                math.max((h[i] - c[i - 1]).abs(), (l[i] - c[i - 1]).abs()),
              ),
    ];
    atr = _rma(tr, 14);
    final vma20 = _sma(v, 20);
    rvol = [
      for (var i = 0; i < n; i++)
        vma20[i] == null || vma20[i] == 0 ? null : v[i]! / vma20[i]!,
    ];
    sma50 = _sma(c, 50);
    sma200 = _sma(c, 200);
    ema20 = _ema(c, 20);
    range = [for (var i = 0; i < n; i++) h[i] - l[i]];
    rangeMed20 = _sma(range, 20);
    bodyMed20 = _sma([for (var i = 0; i < n; i++) (c[i] - o[i]).abs()], 20);
  }

  final List<PricePoint> history;
  final int n;
  final List<double> o;
  final List<double> h;
  final List<double> l;
  final List<double> c;
  late final List<double?> rsi;
  late final List<double?> srK;
  late final List<double?> srD;
  late final List<double?> macd;
  late final List<double?> sig;
  late final List<double?> atr;
  late final List<double?> rvol;
  late final List<double?> sma50;
  late final List<double?> sma200;
  late final List<double?> ema20;
  late final List<double> range;
  late final List<double?> rangeMed20;
  late final List<double?> bodyMed20;

  ScanTrend? trendAt(int t) {
    if (t < 10 || sma200[t] == null || sma50[t - 10] == null) return null;
    final s50 = sma50[t]!;
    final s200 = sma200[t]!;
    final p50 = sma50[t - 10]!;
    if (c[t] > s50 && s50 > s200 && s50 > p50) return ScanTrend.up;
    if (c[t] < s50 && s50 < s200 && s50 < p50) return ScanTrend.down;
    return ScanTrend.side;
  }

  /// Pola candlestick pada bar terakhir. Pola bullish hanya dicari bila
  /// harga di bawah EMA20 (hari ini atau kemarin), bearish bila di atasnya.
  List<CandlePattern> candles() {
    final t = n - 1;
    final out = <CandlePattern>[];
    if (t < 22 || rangeMed20[t] == null || bodyMed20[t] == null) return out;
    if (range[t] < 5 * _tick(c[t])) return out;
    double body(int i) => (c[i] - o[i]).abs();
    double up(int i) => h[i] - math.max(o[i], c[i]);
    double dn(int i) => math.min(o[i], c[i]) - l[i];
    bool black(int i) => c[i] < o[i];
    bool white(int i) => c[i] > o[i];
    bool long(int i) =>
        body(i) >= (bodyMed20[i] ?? double.infinity) && body(i) > 0;
    final rg = range[t];
    final rm = rangeMed20[t]!;
    bool below(int i) => ema20[i] != null && c[i] < ema20[i]!;
    bool above(int i) => ema20[i] != null && c[i] > ema20[i]!;
    if (below(t) || below(t - 1)) {
      if (dn(t) >= 2 * body(t) && up(t) <= 0.1 * rg && rg >= rm) {
        out.add(CandlePattern.hammer);
      }
      if (black(t - 1) &&
          white(t) &&
          o[t] <= c[t - 1] &&
          c[t] >= o[t - 1] &&
          body(t) > body(t - 1)) {
        out.add(CandlePattern.bullishEngulfing);
      }
      if (black(t - 1) &&
          long(t - 1) &&
          white(t) &&
          o[t] < c[t - 1] &&
          c[t] > (o[t - 1] + c[t - 1]) / 2 &&
          c[t] < o[t - 1]) {
        out.add(CandlePattern.piercing);
      }
      if (black(t - 2) &&
          long(t - 2) &&
          body(t - 1) <= 0.3 * body(t - 2) &&
          math.max(o[t - 1], c[t - 1]) < c[t - 2] &&
          white(t) &&
          c[t] > (o[t - 2] + c[t - 2]) / 2) {
        out.add(CandlePattern.morningStar);
      }
      if (black(t - 1) &&
          long(t - 1) &&
          white(t) &&
          o[t] > c[t - 1] &&
          c[t] < o[t - 1]) {
        out.add(CandlePattern.bullishHarami);
      }
    }
    if (above(t) || above(t - 1)) {
      if (up(t) >= 2 * body(t) && dn(t) <= 0.1 * rg && rg >= rm) {
        out.add(CandlePattern.shootingStar);
      }
      if (white(t - 1) &&
          black(t) &&
          o[t] >= c[t - 1] &&
          c[t] <= o[t - 1] &&
          body(t) > body(t - 1)) {
        out.add(CandlePattern.bearishEngulfing);
      }
      if (white(t - 1) &&
          long(t - 1) &&
          black(t) &&
          o[t] > c[t - 1] &&
          c[t] < (o[t - 1] + c[t - 1]) / 2 &&
          c[t] > o[t - 1]) {
        out.add(CandlePattern.darkCloud);
      }
      if (white(t - 2) &&
          long(t - 2) &&
          body(t - 1) <= 0.3 * body(t - 2) &&
          math.min(o[t - 1], c[t - 1]) > c[t - 2] &&
          black(t) &&
          c[t] < (o[t - 2] + c[t - 2]) / 2) {
        out.add(CandlePattern.eveningStar);
      }
      if (white(t - 1) &&
          long(t - 1) &&
          black(t) &&
          o[t] < c[t - 1] &&
          c[t] > o[t - 1]) {
        out.add(CandlePattern.bearishHarami);
      }
    }
    return out;
  }

  /// Syarat E5, B4, dan A4 pada bar terakhir. Kosong bila data kurang.
  List<ScenarioCheck> scenarios() {
    final t = n - 1;
    if (t < 61 || rsi[t] == null || macd[t] == null || sig[t] == null) {
      return const [];
    }
    final r = rsi[t]!;
    final trend = trendAt(t);
    bool yes(bool x) => x;
    int count(List<bool> xs) => xs.where(yes).length;

    // E5: tren SIDE; StochRSI K memotong D ke atas dengan K < 20; RSI 40-50.
    final k0 = srK[t], d0 = srD[t], k1 = srK[t - 1], d1 = srD[t - 1];
    final e5 = [
      trend == ScanTrend.side,
      k0 != null &&
          d0 != null &&
          k1 != null &&
          d1 != null &&
          k1 <= d1 &&
          k0 > d0 &&
          k0 < 20,
      r >= 40 && r <= 50,
    ];

    // B4: tren UP; low terendah 5 bar dan lebih tinggi dari low acuan; RSI
    // lebih rendah dari RSI di low acuan (selisih > 3); RSI 30-50.
    var j = t - 20;
    for (var i = t - 20; i < t - 4; i++) {
      if (l[i] < l[j]) j = i;
    }
    final low5 = l.sublist(t - 4, t + 1).reduce(math.min);
    final b4 = [
      trend == ScanTrend.up,
      l[t] == low5 && l[t] > l[j],
      rsi[j] != null && r < rsi[j]! - 3,
      r >= 30 && r <= 50,
    ];

    // A4: MACD memotong sinyal ke atas; MACD < 0; RSI <= 20 dalam 5 bar;
    // volume kemarin >= rata-rata 20 hari.
    final crossUp =
        macd[t - 1] != null &&
        sig[t - 1] != null &&
        macd[t - 1]! <= sig[t - 1]! &&
        macd[t]! > sig[t]!;
    final rsi5 = [for (var q = t - 4; q <= t; q++) rsi[q]];
    final a4 = [
      crossUp,
      macd[t]! < 0,
      rsi5.every((x) => x != null) &&
          rsi5.map((x) => x!).reduce(math.min) <= 20,
      rvol[t - 1] != null && rvol[t - 1]! >= 1,
    ];
    return [
      ScenarioCheck(code: 'E5', met: count(e5), total: e5.length),
      ScenarioCheck(code: 'B4', met: count(b4), total: b4.length),
      ScenarioCheck(code: 'A4', met: count(a4), total: a4.length),
    ];
  }

  /// Deteksi pola chart terakhir yang breakout-nya dalam [recentBars] bar
  /// terakhir. Null bila tidak ada.
  ChartPatternEvent? latestChartPattern({int recentBars = 10}) {
    final events = _detectPatterns();
    _PatEvent? best;
    for (final e in events) {
      if (e.t >= n - recentBars && (best == null || e.t >= best.t)) best = e;
    }
    if (best == null) return null;
    return ChartPatternEvent(
      kind: best.kind,
      breakout: history[best.t].date,
      keyDates: [for (final k in best.key) history[k].date],
    );
  }

  List<_PatEvent> _detectPatterns() {
    final atrPct = [
      for (var i = 0; i < n; i++) atr[i] == null ? null : atr[i]! / c[i],
    ];
    final piv = <_Pivot>[];
    final events = <_PatEvent>[];
    final used = <String>{};
    void emit(int t, ChartPatternKind kind, List<int> key) {
      final id = '${kind.name}:${key.join(',')}';
      if (used.add(id)) events.add(_PatEvent(t, kind, key));
    }

    var dir = 0;
    var cH = 0;
    var cL = 0;
    for (var i = 1; i < n; i++) {
      final th = math.max(0.03, 2.5 * (atrPct[i] ?? 0));
      if (dir == 0) {
        if (h[i] > h[cH]) cH = i;
        if (l[i] < l[cL]) cL = i;
        if (cL != i && h[i] >= l[cL] * (1 + th)) {
          piv.add(_Pivot(cL, l[cL], low: true));
          dir = 1;
          cH = i;
        } else if (cH != i && l[i] <= h[cH] * (1 - th)) {
          piv.add(_Pivot(cH, h[cH], low: false));
          dir = -1;
          cL = i;
        }
      } else if (dir == 1) {
        if (h[i] > h[cH]) {
          cH = i;
        } else if (l[i] <= h[cH] * (1 - th)) {
          piv.add(_Pivot(cH, h[cH], low: false));
          dir = -1;
          cL = i;
        }
      } else {
        if (l[i] < l[cL]) {
          cL = i;
        } else if (h[i] >= l[cL] * (1 + th)) {
          piv.add(_Pivot(cL, l[cL], low: true));
          dir = 1;
          cH = i;
        }
      }
      final a = atrPct[i];
      final m = piv.length;
      if (a == null || i < 60 || m < 3) continue;
      _doubles(i, a, piv, emit);
      if (m >= 5) _headShoulders(i, a, piv, emit);
      if (m >= 4) _triangle(i, a, piv, emit);
      _flags(i, piv, emit);
    }
    return events;
  }

  double _maxH(int from, int to) {
    var mx = double.negativeInfinity;
    for (var q = math.max(0, from); q <= to; q++) {
      mx = math.max(mx, h[q]);
    }
    return mx;
  }

  double _minL(int from, int to) {
    var mn = double.infinity;
    for (var q = math.max(0, from); q <= to; q++) {
      mn = math.min(mn, l[q]);
    }
    return mn;
  }

  void _doubles(
    int i,
    double a,
    List<_Pivot> piv,
    void Function(int, ChartPatternKind, List<int>) emit,
  ) {
    final m = piv.length;
    final p = piv[m - 3], b = piv[m - 2], d = piv[m - 1];
    final gap = d.idx - p.idx;
    if (p.low && !b.low && d.low) {
      final height = b.price / math.max(p.price, d.price) - 1;
      if (height >= math.max(0.05, 3 * a) &&
          (d.price / p.price - 1).abs() <= math.min(0.04, 0.3 * height) &&
          gap >= 10 &&
          gap <= 70 &&
          c[i] > b.price &&
          i - d.idx <= 25 &&
          _maxH(p.idx - 40, p.idx) >= p.price * (1 + height)) {
        emit(i, ChartPatternKind.doubleBottom, [p.idx, b.idx, d.idx]);
      }
    }
    if (!p.low && b.low && !d.low) {
      final height = math.min(p.price, d.price) / b.price - 1;
      if (height >= math.max(0.05, 3 * a) &&
          (d.price / p.price - 1).abs() <= math.min(0.04, 0.3 * height) &&
          gap >= 10 &&
          gap <= 70 &&
          c[i] < b.price &&
          i - d.idx <= 25 &&
          _minL(p.idx - 40, p.idx) <= p.price / (1 + height)) {
        emit(i, ChartPatternKind.doubleTop, [p.idx, b.idx, d.idx]);
      }
    }
  }

  void _headShoulders(
    int i,
    double a,
    List<_Pivot> piv,
    void Function(int, ChartPatternKind, List<int>) emit,
  ) {
    final m = piv.length;
    final p1 = piv[m - 5], t1 = piv[m - 4], p2 = piv[m - 3];
    final t2 = piv[m - 2], p3 = piv[m - 1];
    double neckAt(int x) =>
        t1.price + (t2.price - t1.price) * (x - t1.idx) / (t2.idx - t1.idx);
    final mid = (t1.price + t2.price) / 2;
    final span = p3.idx - p1.idx;
    final key = [p1.idx, t1.idx, p2.idx, t2.idx, p3.idx];
    final common =
        (p3.price / p1.price - 1).abs() <= 0.1 &&
        (t2.price / t1.price - 1).abs() <= 0.08 &&
        span >= 15 &&
        span <= 120 &&
        i - p3.idx <= 40;
    if (!p1.low && t1.low && !p2.low && t2.low && !p3.low) {
      if (common &&
          p2.price > math.max(p1.price, p3.price) * (1 + math.max(0.02, a)) &&
          p2.price / mid - 1 >= 0.05 &&
          c[i] < neckAt(i) &&
          _minL(p1.idx - 40, p1.idx) <= p1.price * (1 - 0.06)) {
        emit(i, ChartPatternKind.headShoulders, key);
      }
    }
    if (p1.low && !t1.low && p2.low && !t2.low && p3.low) {
      if (common &&
          p2.price < math.min(p1.price, p3.price) * (1 - math.max(0.02, a)) &&
          mid / p2.price - 1 >= 0.05 &&
          c[i] > neckAt(i) &&
          _maxH(p1.idx - 40, p1.idx) >= p1.price * (1 + 0.06)) {
        emit(i, ChartPatternKind.inverseHeadShoulders, key);
      }
    }
  }

  void _triangle(
    int i,
    double a,
    List<_Pivot> piv,
    void Function(int, ChartPatternKind, List<int>) emit,
  ) {
    final m = piv.length;
    final q4 = piv.sublist(m - 4);
    final hs = [
      for (final x in q4)
        if (!x.low) x,
    ];
    final ls = [
      for (final x in q4)
        if (x.low) x,
    ];
    final span = q4[3].idx - q4[0].idx;
    if (hs.length != 2 || ls.length != 2) return;
    if (span < 15 || span > 80 || i - q4[3].idx > 30) return;
    final hA = hs[0], hB = hs[1], lA = ls[0], lB = ls[1];
    final uRel = hB.price / hA.price - 1;
    final lRel = lB.price / lA.price - 1;
    String? shape;
    if (uRel.abs() <= 0.015 && lRel >= 0.03) {
      shape = 'asc';
    } else if (lRel.abs() <= 0.015 && uRel <= -0.03) {
      shape = 'desc';
    } else if (uRel <= -0.03 && lRel >= 0.03) {
      shape = 'sym';
    }
    if (shape == null) return;
    double up(int x) =>
        hA.price + (hB.price - hA.price) * (x - hA.idx) / (hB.idx - hA.idx);
    double lo(int x) =>
        lA.price + (lB.price - lA.price) * (x - lA.idx) / (lB.idx - lA.idx);
    final x0 = math.max(hA.idx, lA.idx);
    final width0 = (up(x0) - lo(x0)) / ((up(x0) + lo(x0)) / 2);
    if (!(up(i) > lo(i) && width0 >= math.max(0.05, 3 * a))) return;
    final brkUp = c[i] > up(i);
    final brkDn = c[i] < lo(i);
    if (!brkUp && !brkDn) return;
    for (var x = x0; x < i; x++) {
      if (h[x] > up(x) * 1.01 || l[x] < lo(x) * 0.99) return;
    }
    final kind = switch ((shape, brkUp)) {
      ('asc', true) => ChartPatternKind.ascendingUp,
      ('asc', false) => ChartPatternKind.ascendingDown,
      ('desc', true) => ChartPatternKind.descendingUp,
      ('desc', false) => ChartPatternKind.descendingDown,
      (_, true) => ChartPatternKind.symmetricUp,
      (_, false) => ChartPatternKind.symmetricDown,
    };
    emit(i, kind, [for (final x in q4) x.idx]);
  }

  void _flags(
    int i,
    List<_Pivot> piv,
    void Function(int, ChartPatternKind, List<int>) emit,
  ) {
    final m = piv.length;
    for (var j = math.max(0, m - 7); j <= m - 1; j++) {
      final q = piv[j];
      if (q.idx < 20) continue;
      final age = i - q.idx;
      if (age < 4 || age > 25) continue;
      if (!q.low) {
        var s0 = q.idx - 20;
        for (var x = q.idx - 20; x <= q.idx; x++) {
          if (l[x] < l[s0]) s0 = x;
        }
        final pole = q.price / l[s0] - 1;
        if (pole >= 0.1 && c[i] > q.price && c[i - 1] <= q.price) {
          final minL = _minL(q.idx + 1, i - 1);
          final maxH = _maxH(q.idx + 1, i - 1);
          if ((q.price - minL) / (q.price - l[s0]) <= 0.5 && maxH <= q.price) {
            emit(i, ChartPatternKind.bullFlag, [s0, q.idx]);
          }
        }
      } else {
        var s0 = q.idx - 20;
        for (var x = q.idx - 20; x <= q.idx; x++) {
          if (h[x] > h[s0]) s0 = x;
        }
        final pole = h[s0] / q.price - 1;
        if (pole >= 0.1 && c[i] < q.price && c[i - 1] >= q.price) {
          final minL = _minL(q.idx + 1, i - 1);
          final maxH = _maxH(q.idx + 1, i - 1);
          if ((maxH - q.price) / (h[s0] - q.price) <= 0.5 && minL >= q.price) {
            emit(i, ChartPatternKind.bearFlag, [s0, q.idx]);
          }
        }
      }
    }
  }
}

class _Pivot {
  const _Pivot(this.idx, this.price, {required this.low});

  final int idx;
  final double price;
  final bool low;
}

class _PatEvent {
  const _PatEvent(this.t, this.kind, this.key);

  final int t;
  final ChartPatternKind kind;
  final List<int> key;
}
