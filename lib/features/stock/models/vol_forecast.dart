/// Perkiraan model untuk rata-rata gerak harian 10 hari bursa setelah
/// [asOf] (tabel `ml_vol`). Hanya besar gerak, bukan arah.
class VolForecast {
  const VolForecast({
    required this.ticker,
    required this.asOf,
    required this.move,
  });

  final String ticker;

  /// Tanggal data harga terakhir yang dipakai model.
  final DateTime asOf;

  /// Gerak harian dalam persen: 2,1 berarti naik atau turun sekitar 2,1% per hari.
  final double move;

  /// Null bila baris tidak lengkap atau angkanya tidak masuk akal.
  static VolForecast? tryFromMap(Map<String, dynamic> map) {
    final ticker = map['ticker'];
    final asOf = DateTime.tryParse('${map['as_of']}');
    final raw = map['forecast_move'];
    final move = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (ticker is! String || asOf == null || move == null || move <= 0) {
      return null;
    }
    return VolForecast(ticker: ticker, asOf: asOf, move: move);
  }
}
