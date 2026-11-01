/// Hasil model ML untuk satu saham (tabel `ml_prediction`) beserta tanggal
/// dan ringkasan akurasi model aktifnya (tabel `ml_model`).
///
/// Ini penyaring informasi, bukan rekomendasi beli atau jual. Akurasi model
/// masih lemah, jadi nilainya selalu ditampilkan bersama tanggal model.
class MlPrediction {
  const MlPrediction({
    required this.ticker,
    required this.tradeDate,
    required this.modelVersion,
    required this.horizonDays,
    required this.probUp,
    required this.baseRate,
    required this.signal,
    required this.upperPct,
    required this.lowerPct,
    required this.drivers,
    this.closePrice,
    this.modelTrainedAt,
    this.aucFolds = const [],
    this.inUniverse,
    this.backtest,
    this.outcome,
  });

  final String ticker;

  /// Hari perdagangan terakhir yang dipakai untuk membuat prediksi.
  final DateTime tradeDate;
  final String modelVersion;

  /// Jumlah hari perdagangan ke depan yang dinilai, misalnya 10.
  final int horizonDays;

  /// Peluang harga menyentuh batas atas lebih dulu, 0 sampai 1.
  final double probUp;

  /// Rata-rata historis peluang yang sama, 0 sampai 1.
  final double baseRate;
  final MlSignal signal;

  /// Batas atas dan bawah sebagai pecahan: 0,17 berarti +17%.
  final double upperPct;
  final double lowerPct;
  final double? closePrice;
  final List<MlDriver> drivers;
  final DateTime? modelTrainedAt;

  /// AUC per lipatan uji dari model.
  final List<double> aucFolds;

  /// True bila saham ini ikut data latih model, null bila model tidak
  /// menyimpan daftarnya. Di luar data latih, skornya kurang bisa dipercaya.
  final bool? inUniverse;

  /// Uji balik model aktif, null bila model belum menyimpannya.
  final MlBacktest? backtest;

  /// Hasil nyata prediksi ini, null selama belum genap horizon hari bursa.
  final MlOutcome? outcome;

  double? get aucMean => aucFolds.isEmpty
      ? null
      : aucFolds.reduce((a, b) => a + b) / aucFolds.length;

  double? get aucMin =>
      aucFolds.isEmpty ? null : aucFolds.reduce((a, b) => a < b ? a : b);

  double? get aucMax =>
      aucFolds.isEmpty ? null : aucFolds.reduce((a, b) => a > b ? a : b);

  /// Fitur dengan sumbangan terbesar ke skor, tanpa melihat arahnya.
  List<MlDriver> topDrivers(int count) {
    final sorted = [...drivers]
      ..sort((a, b) => b.contribution.abs().compareTo(a.contribution.abs()));
    return sorted.take(count).toList();
  }

  /// Null bila baris tidak lengkap atau sinyalnya tidak dikenal.
  static MlPrediction? tryFromMap(Map<String, dynamic> map) {
    final signal = _parseSignal(map['signal']);
    final date = DateTime.tryParse('${map['trade_date']}');
    final probUp = _asDouble(map['prob_up']);
    final baseRate = _asDouble(map['base_rate']);
    final upper = _asDouble(map['upper_pct']);
    final lower = _asDouble(map['lower_pct']);
    final horizon = _asDouble(map['horizon_days'])?.round();
    final ticker = map['ticker'];
    if (signal == null ||
        date == null ||
        probUp == null ||
        baseRate == null ||
        upper == null ||
        lower == null ||
        horizon == null ||
        ticker is! String) {
      return null;
    }
    final model = map['ml_model'];
    final modelMap = model is Map<String, dynamic>
        ? model
        : const <String, dynamic>{};
    final version = map['model_version'];
    return MlPrediction(
      ticker: ticker,
      tradeDate: date,
      modelVersion: version is String ? version : '-',
      horizonDays: horizon,
      probUp: probUp,
      baseRate: baseRate,
      signal: signal,
      upperPct: upper,
      lowerPct: lower,
      closePrice: _asDouble(map['close_price']),
      drivers: _parseDrivers(map['drivers']),
      modelTrainedAt: DateTime.tryParse('${modelMap['trained_at']}')?.toLocal(),
      aucFolds: _aucFolds(modelMap['metrics']),
      inUniverse: switch (modelMap['universe']) {
        final List<dynamic> list => list.contains(ticker),
        _ => null,
      },
      backtest: MlBacktest.tryFrom(modelMap['metrics']),
      outcome: MlOutcome.tryFrom(map),
    );
  }
}

/// Ringkasan uji balik model aktif dari `ml_model.metrics.backtest`. Semua
/// angka pecahan dan sudah dikurangi biaya. Ditulis ulang tiap latih ulang.
class MlBacktest {
  const MlBacktest({
    required this.top10,
    required this.all,
    required this.nStocks,
    required this.periods,
    required this.horizonDays,
    required this.costRoundTrip,
    this.testStart,
    this.testEnd,
    this.rule,
  });

  /// Transaksi dari 10% skor teratas tiap hari.
  final MlBacktestGroup top10;

  /// Semua transaksi, sebagai pembanding.
  final MlBacktestGroup all;
  final int nStocks;
  final int periods;
  final int horizonDays;
  final double costRoundTrip;
  final DateTime? testStart;
  final DateTime? testEnd;

  /// Aturan uji dalam kalimat, misalnya kapan masuk dan keluar.
  final String? rule;

  static MlBacktest? tryFrom(Object? metrics) {
    if (metrics is! Map) return null;
    final raw = metrics['backtest'];
    if (raw is! Map) return null;
    final top10 = MlBacktestGroup.tryFrom(raw['top10']);
    final all = MlBacktestGroup.tryFrom(raw['all']);
    if (top10 == null || all == null) return null;
    final rule = raw['rule'];
    return MlBacktest(
      top10: top10,
      all: all,
      nStocks: _asDouble(raw['nStocks'])?.round() ?? 0,
      periods: _asDouble(raw['periods'])?.round() ?? 0,
      horizonDays: _asDouble(raw['horizonDays'])?.round() ?? 0,
      costRoundTrip: _asDouble(raw['costRoundTrip']) ?? 0,
      testStart: DateTime.tryParse('${raw['testStart']}'),
      testEnd: DateTime.tryParse('${raw['testEnd']}'),
      rule: rule is String && rule.isNotEmpty ? rule : null,
    );
  }
}

/// Satu kelompok transaksi uji balik.
class MlBacktestGroup {
  const MlBacktestGroup({
    required this.winRate,
    required this.avgWin,
    required this.avgLoss,
    required this.netPerTrade,
    required this.trades,
  });

  final double winRate;
  final double avgWin;
  final double avgLoss;
  final double netPerTrade;
  final int trades;

  static MlBacktestGroup? tryFrom(Object? raw) {
    if (raw is! Map) return null;
    final winRate = _asDouble(raw['winRate']);
    final avgWin = _asDouble(raw['avgWin']);
    final avgLoss = _asDouble(raw['avgLoss']);
    final net = _asDouble(raw['netPerTrade']);
    if (winRate == null || avgWin == null || avgLoss == null || net == null) {
      return null;
    }
    return MlBacktestGroup(
      winRate: winRate,
      avgWin: avgWin,
      avgLoss: avgLoss,
      netPerTrade: net,
      trades: _asDouble(raw['trades'])?.round() ?? 0,
    );
  }
}

/// Hasil nyata satu prediksi setelah genap horizon hari bursa (kolom
/// `outcome_*`). Null selama prediksi belum matang.
class MlOutcome {
  const MlOutcome({
    required this.date,
    required this.retNet,
    this.entry,
    this.exit,
    this.win,
    this.hitUpper,
  });

  /// Hari bursa saat hasil dihitung.
  final DateTime date;

  /// Hasil bersih setelah biaya, pecahan.
  final double retNet;
  final double? entry;
  final double? exit;
  final bool? win;
  final bool? hitUpper;

  static MlOutcome? tryFrom(Map<String, dynamic> map) {
    final date = DateTime.tryParse('${map['outcome_date']}');
    final ret = _asDouble(map['outcome_ret_net']);
    if (date == null || ret == null) return null;
    final win = map['outcome_win'];
    final hit = map['outcome_hit_upper'];
    return MlOutcome(
      date: date,
      retNet: ret,
      entry: _asDouble(map['outcome_entry']),
      exit: _asDouble(map['outcome_exit']),
      win: win is bool ? win : null,
      hitUpper: hit is bool ? hit : null,
    );
  }
}

/// Sinyal penyaring. Labelnya sama dengan nilai `signal` di database.
enum MlSignal { peluang, netral, risiko }

/// Satu fitur yang ikut menggeser skor. [contribution] positif berarti
/// mendorong peluang naik, negatif berarti menekannya.
class MlDriver {
  const MlDriver({
    required this.feature,
    required this.contribution,
    this.value,
  });

  final String feature;
  final double contribution;
  final double? value;

  bool get pushesUp => contribution > 0;
}

MlSignal? _parseSignal(Object? raw) => switch (raw) {
  'peluang' => MlSignal.peluang,
  'netral' => MlSignal.netral,
  'risiko' => MlSignal.risiko,
  _ => null,
};

/// PostgREST bisa mengirim angka numerik sebagai angka atau sebagai teks.
double? _asDouble(Object? raw) => switch (raw) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

List<MlDriver> _parseDrivers(Object? raw) {
  if (raw is! List) return const [];
  final out = <MlDriver>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final feature = item['feature'];
    final contribution = _asDouble(item['contribution']);
    if (feature is! String || contribution == null) continue;
    out.add(
      MlDriver(
        feature: feature,
        contribution: contribution,
        value: _asDouble(item['value']),
      ),
    );
  }
  return out;
}

/// AUC per lipatan dari kolom `metrics.folds`. Model yang strukturnya lain
/// menghasilkan daftar kosong, jadi UI cukup menyembunyikan baris akurasi.
List<double> _aucFolds(Object? metrics) {
  if (metrics is! Map) return const [];
  final folds = metrics['folds'];
  if (folds is! List) return const [];
  final out = <double>[];
  for (final fold in folds) {
    if (fold is! Map) continue;
    final auc = _asDouble(fold['auc']);
    if (auc != null) out.add(auc);
  }
  return out;
}
