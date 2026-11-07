import 'dart:math' as math;

import '../models/price_point.dart';

/// Panjang jendela yang dinilai tab Risiko: 10 hari bursa setelah hari acuan.
const riskHorizon = 10;

/// CL (persen turun dari penutupan hari acuan) yang ditampilkan di kartu
/// frekuensi. Batas wajar pemakai 1 sampai 4%, 5% adalah CL, 7% pembanding.
const riskCutLosses = [2, 3, 4, 5, 7];

/// Jumlah jendela terakhir (kira-kira setahun bursa) untuk pembanding "setahun
/// terakhir". Frekuensi sejak 2021 bercampur pasar tenang dan pasar keras, dan
/// uji lab 7 Nov 2026 menunjukkan frekuensinya naik di periode-periode akhir.
const riskRecentWindows = 250;

/// Seberapa liar harga sekarang dibanding biasanya (rasio gerak 20 hari
/// terakhir terhadap median setahun). Batas rasio adalah pilihan tampilan
/// app, bukan hasil uji.
enum VolatilityState { calm, usual, wild, veryWild }

/// Seberapa sering harga terendah dalam 10 hari bursa menyentuh CL tertentu.
class TouchRate {
  const TouchRate({required this.cutLoss, required this.all, this.recent});

  /// CL dalam persen, mis. 5 berarti turun 5% dari penutupan hari acuan.
  final double cutLoss;

  /// Bagian jendela (0 sampai 1) yang menyentuh CL, dari seluruh riwayat.
  final double all;

  /// Sama, tetapi hanya [riskRecentWindows] jendela terakhir. Null bila
  /// riwayat terlalu pendek untuk pembanding.
  final double? recent;
}

/// Ukuran gerak harga dari `price_history`: gerak harian terukur dan seberapa
/// sering CL tersentuh. Semuanya hitungan frekuensi masa lalu, bukan keluaran
/// model dan bukan perkiraan arah.
class RiskAnalysis {
  const RiskAnalysis({
    required this.firstDate,
    required this.lastDate,
    required this.lastClose,
    required this.moveNow,
    required this.moveTypical,
    required this.windows,
    required this.rates,
    required this.drops,
  });

  /// Tanggal data pertama dan terakhir yang dipakai.
  final DateTime firstDate;
  final DateTime lastDate;
  final double lastClose;

  /// Simpangan baku return harian 20 hari terakhir, dalam persen.
  final double moveNow;

  /// Median simpangan baku 20 hari selama setahun bursa terakhir, dalam persen.
  final double moveTypical;

  /// Jumlah jendela 10 hari yang lengkap.
  final int windows;

  final List<TouchRate> rates;

  /// Penurunan terdalam tiap jendela 10 hari (0,05 berarti harga terendah 5%
  /// di bawah penutupan hari acuan), terlama dulu.
  final List<double> drops;

  /// Gerak sekarang dibanding biasanya: 1,5 berarti 1,5 kali lebih liar.
  double get ratio => moveTypical <= 0 ? 1 : moveNow / moveTypical;

  VolatilityState get state => switch (ratio) {
    < 0.8 => VolatilityState.calm,
    < 1.25 => VolatilityState.usual,
    < 1.8 => VolatilityState.wild,
    _ => VolatilityState.veryWild,
  };

  /// Frekuensi untuk CL [cutLoss] persen, mis. 4,5. Pembanding setahun null
  /// bila riwayat terlalu pendek.
  TouchRate rateAt(double cutLoss) => _rate(drops, cutLoss);

  /// Hitung dari riwayat harga (terlama dulu). Null bila terlalu pendek untuk
  /// angka yang berarti: butuh minimal 80 hari bursa.
  ///
  /// Sebuah jendela menyentuh CL bila harga terendah (low) salah satu dari 10
  /// hari berikutnya sampai di CL atau di bawahnya, dihitung dari penutupan
  /// hari acuan. Lompat harga saat buka tidak dipisahkan dari harga terendah.
  static RiskAnalysis? from(
    List<PricePoint> history, {
    List<int> cutLosses = riskCutLosses,
  }) {
    if (history.length < 80) return null;
    final n = history.length;
    final windows = n - riskHorizon;
    final drops = <double>[];
    for (var i = 0; i < windows; i++) {
      var minLow = double.infinity;
      for (var j = i + 1; j <= i + riskHorizon; j++) {
        minLow = math.min(minLow, history[j].lowOrClose);
      }
      drops.add(1 - minLow / history[i].close);
    }
    final rates = [for (final cl in cutLosses) _rate(drops, cl.toDouble())];

    final returns = <double>[
      for (var i = 1; i < n; i++)
        math.log(history[i].close / history[i - 1].close),
    ];
    // Simpangan baku sampel 20 hari yang berakhir di tiap hari.
    final rolling = <double>[];
    for (var end = 19; end < returns.length; end++) {
      rolling.add(_std(returns.sublist(end - 19, end + 1)));
    }
    final lastYear = rolling.length > riskRecentWindows
        ? rolling.sublist(rolling.length - riskRecentWindows)
        : rolling;
    final sorted = [...lastYear]..sort();
    final middle = sorted.length ~/ 2;
    final typical = sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;

    return RiskAnalysis(
      firstDate: history.first.date,
      lastDate: history.last.date,
      lastClose: history.last.close,
      moveNow: rolling.last * 100,
      moveTypical: typical * 100,
      windows: windows,
      rates: rates,
      drops: drops,
    );
  }
}

TouchRate _rate(List<double> drops, double cl) {
  // Toleransi kecil supaya penurunan tepat 5,0% terhitung menyentuh.
  const eps = 1e-9;
  double share(int from) {
    var hit = 0;
    for (var i = from; i < drops.length; i++) {
      if (drops[i] >= cl / 100 - eps) hit++;
    }
    return hit / (drops.length - from);
  }

  final recentFrom = drops.length - riskRecentWindows;
  return TouchRate(
    cutLoss: cl,
    all: share(0),
    recent: recentFrom >= 20 ? share(recentFrom) : null,
  );
}

double _std(List<double> values) {
  final mean = values.fold<double>(0, (a, b) => a + b) / values.length;
  var sum = 0.0;
  for (final v in values) {
    sum += (v - mean) * (v - mean);
  }
  return math.sqrt(sum / (values.length - 1));
}

/// Hasil hitungan ukuran posisi.
class PositionSize {
  const PositionSize({
    required this.lots,
    required this.cost,
    required this.stopPrice,
    required this.loss,
    required this.limitedByCapital,
  });

  final int lots;

  /// Nilai pembelian dalam rupiah (lot × 100 lembar × harga).
  final double cost;

  /// Harga saat CL tersentuh.
  final double stopPrice;

  /// Rugi bila CL tersentuh tepat di [stopPrice], tanpa biaya transaksi.
  final double loss;

  /// True bila jumlah lot dibatasi modal, jadi rugi di CL lebih kecil dari
  /// batas risiko yang ditetapkan.
  final bool limitedByCapital;
}

/// Lot terbanyak yang rugi di CL-nya tidak melewati [riskPercent] dari
/// [capital]. Satu lot 100 lembar. Tidak memperhitungkan biaya transaksi dan
/// fraksi harga. Null bila masukan tidak masuk akal atau satu lot pun tidak
/// muat dalam batas risiko.
PositionSize? positionSize({
  required double capital,
  required double riskPercent,
  required double cutLossPercent,
  required double price,
}) {
  if (capital <= 0 || riskPercent <= 0 || cutLossPercent <= 0 || price <= 0) {
    return null;
  }
  final lossPerShare = price * cutLossPercent / 100;
  final byRisk = (capital * riskPercent / 100 / lossPerShare / 100).floor();
  final byCapital = (capital / (price * 100)).floor();
  final lots = math.min(byRisk, byCapital);
  if (lots < 1) return null;
  return PositionSize(
    lots: lots,
    cost: lots * 100 * price,
    stopPrice: price - lossPerShare,
    loss: lots * 100 * lossPerShare,
    limitedByCapital: byCapital < byRisk,
  );
}
