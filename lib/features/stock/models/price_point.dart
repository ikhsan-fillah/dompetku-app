/// Satu hari harga dari tabel `price_history` (data harian bersumber Yahoo,
/// diisi pipeline ML). Dipakai untuk rata-rata panjang (MA50, MA200),
/// volatilitas, dan IHSG, yang tidak tersedia di `daily_snapshot`.
class PricePoint {
  const PricePoint({
    required this.ticker,
    required this.date,
    required this.close,
    this.open,
    this.high,
    this.low,
    this.volume,
  });

  final String ticker;
  final DateTime date;
  final double close;
  final double? open;
  final double? high;
  final double? low;

  /// Volume dalam lembar saham (bukan lot).
  final double? volume;

  double get highOrClose => high ?? close;
  double get lowOrClose => low ?? close;

  /// Null bila baris tidak punya tanggal atau harga penutupan.
  static PricePoint? tryFromMap(Map<String, dynamic> map) {
    final ticker = map['ticker'];
    final date = DateTime.tryParse('${map['trade_date']}');
    final close = _num(map['close_price']);
    if (ticker is! String || date == null || close == null || close <= 0) {
      return null;
    }
    return PricePoint(
      ticker: ticker,
      date: date,
      close: close,
      open: _num(map['open_price']),
      high: _num(map['high_price']),
      low: _num(map['low_price']),
      volume: _num(map['volume']),
    );
  }
}

double? _num(Object? raw) => switch (raw) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};
