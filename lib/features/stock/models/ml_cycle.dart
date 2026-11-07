import 'ml_prediction.dart';

/// Satu sisi prediksi dalam siklus: skor, batas, dan hasil nyata bila sudah
/// ada. Dikunci di hari sinyal dan tidak pernah ditimpa.
class MlCycleLeg {
  const MlCycleLeg({
    required this.model,
    required this.probUp,
    required this.baseRate,
    required this.signal,
    required this.upperPct,
    required this.lowerPct,
    this.outcome,
    this.drivers = const [],
  });

  final String model;

  /// Peluang batas atas tersentuh lebih dulu, 0 sampai 1.
  final double probUp;
  final double baseRate;
  final MlSignal signal;

  /// Batas atas dan bawah sebagai pecahan: 0,17 berarti +17%.
  final double upperPct;
  final double lowerPct;

  /// Hasil nyata, null selama hari ke-H belum lewat.
  final MlOutcome? outcome;

  /// Faktor yang menjelaskan skor model ini, kosong bila belum disimpan.
  /// Faktor 5 hari ada di kolom `drivers5`; faktor 10 hari ada di
  /// `ml_prediction`.
  final List<MlDriver> drivers;
}

/// Cara revisi prediksi 10 hari di hari ke-5 dihitung.
enum MlRevisionState {
  /// Dihitung ulang dari jalur harga 5 hari pertama.
  diperbarui,

  /// Batas atas sudah tersentuh di hari 1 sampai 5: hasil 10 hari pasti naik.
  atasTersentuh,

  /// Batas bawah sudah tersentuh di hari 1 sampai 5: hasil 10 hari pasti turun.
  bawahTersentuh,
}

/// Revisi prediksi 10 hari setelah 5 hari nyata. Prediksi awal tetap utuh di
/// [MlCycle.tenDay].
class MlCycleRevision {
  const MlCycleRevision({
    required this.date,
    required this.state,
    required this.probUp,
    this.baseRate,
  });

  /// Hari bursa ke-5, saat revisi dibuat.
  final DateTime date;
  final MlRevisionState state;
  final double probUp;

  /// Rata-rata historis peluang yang sama, null bila hasil sudah ditentukan.
  final double? baseRate;
}

/// Satu siklus 10 hari bursa satu saham (tabel `ml_cycle`): prediksi 5 hari,
/// prediksi 10 hari awal, revisi hari ke-5, dan hasil nyata keduanya.
class MlCycle {
  const MlCycle({
    required this.ticker,
    required this.cycleStart,
    required this.closePrice,
    required this.tenDay,
    this.fiveDay,
    this.revision,
  });

  final String ticker;

  /// Hari ke-0: hari bursa terakhir yang dipakai membuat prediksi.
  final DateTime cycleStart;
  final double closePrice;
  final MlCycleLeg tenDay;

  /// Null bila belum ada model 5 hari yang lolos uji saat siklus dimulai.
  final MlCycleLeg? fiveDay;

  /// Null sebelum hari ke-5 atau bila model revisi belum ada.
  final MlCycleRevision? revision;

  /// Panjang jendela 10 hari bursa.
  static const horizonDays = 10;

  /// Hari ke-5 tempat revisi dibuat.
  static const reviseDay = 5;

  /// True bila hasil nyata 10 hari sudah ada.
  bool get isComplete => tenDay.outcome != null;

  /// Prediksi 10 hari awal dalam bentuk [MlPrediction], untuk kartu yang sama
  /// dengan prediksi harian bila baris `ml_prediction`-nya tidak ada.
  MlPrediction toPrediction() => MlPrediction(
    ticker: ticker,
    tradeDate: cycleStart,
    modelVersion: tenDay.model,
    horizonDays: horizonDays,
    probUp: tenDay.probUp,
    baseRate: tenDay.baseRate,
    signal: tenDay.signal,
    upperPct: tenDay.upperPct,
    lowerPct: tenDay.lowerPct,
    drivers: tenDay.drivers,
    closePrice: closePrice,
    outcome: tenDay.outcome,
  );

  /// Null bila baris tidak lengkap atau sinyalnya tidak dikenal.
  static MlCycle? tryFromMap(Map<String, dynamic> map) {
    final ticker = map['ticker'];
    final start = DateTime.tryParse('${map['cycle_start']}');
    final close = _asDouble(map['close0']);
    final ten = _leg(
      map,
      model: 'model10',
      suffix: '10',
      outcomePrefix: 'out10',
    );
    if (ticker is! String || start == null || close == null || ten == null) {
      return null;
    }
    return MlCycle(
      ticker: ticker,
      cycleStart: start,
      closePrice: close,
      tenDay: ten,
      fiveDay: _leg(
        map,
        model: 'model5',
        suffix: '5',
        outcomePrefix: 'out5',
        driversKey: 'drivers5',
      ),
      revision: _revision(map),
    );
  }
}

MlCycleLeg? _leg(
  Map<String, dynamic> map, {
  required String model,
  required String suffix,
  required String outcomePrefix,
  String? driversKey,
}) {
  final version = map[model];
  final prob = _asDouble(map['prob$suffix']);
  final base = _asDouble(map['base$suffix']);
  final upper = _asDouble(map['upper$suffix']);
  final lower = _asDouble(map['lower$suffix']);
  final signal = switch (map['signal$suffix']) {
    'peluang' => MlSignal.peluang,
    'netral' => MlSignal.netral,
    'risiko' => MlSignal.risiko,
    _ => null,
  };
  if (version is! String ||
      prob == null ||
      base == null ||
      upper == null ||
      lower == null ||
      signal == null) {
    return null;
  }
  return MlCycleLeg(
    model: version,
    probUp: prob,
    baseRate: base,
    signal: signal,
    upperPct: upper,
    lowerPct: lower,
    outcome: _outcome(map, outcomePrefix),
    drivers: driversKey == null ? const [] : parseMlDrivers(map[driversKey]),
  );
}

MlOutcome? _outcome(Map<String, dynamic> map, String prefix) {
  final date = DateTime.tryParse('${map['${prefix}_date']}');
  final ret = _asDouble(map['${prefix}_ret_net']);
  if (date == null || ret == null) return null;
  final win = map['${prefix}_win'];
  final hit = map['${prefix}_hit_upper'];
  return MlOutcome(
    date: date,
    retNet: ret,
    entry: _asDouble(map['${prefix}_entry']),
    exit: _asDouble(map['${prefix}_exit']),
    win: win is bool ? win : null,
    hitUpper: hit is bool ? hit : null,
  );
}

MlCycleRevision? _revision(Map<String, dynamic> map) {
  final date = DateTime.tryParse('${map['rev_date']}');
  final prob = _asDouble(map['rev_prob']);
  final state = switch (map['rev_state']) {
    'diperbarui' => MlRevisionState.diperbarui,
    'atas_tersentuh' => MlRevisionState.atasTersentuh,
    'bawah_tersentuh' => MlRevisionState.bawahTersentuh,
    _ => null,
  };
  if (date == null || prob == null || state == null) return null;
  return MlCycleRevision(
    date: date,
    state: state,
    probUp: prob,
    baseRate: _asDouble(map['rev_base']),
  );
}

/// PostgREST bisa mengirim angka numerik sebagai angka atau sebagai teks.
double? _asDouble(Object? raw) => switch (raw) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};
