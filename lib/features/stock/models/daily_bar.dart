/// Satu hari perdagangan satu saham (tabel `daily_snapshot`): harga, volume,
/// dan nilai indikator yang dibaca dari chart Stockbit.
class DailyBar {
  const DailyBar({
    required this.ticker,
    required this.tradeDate,
    this.open,
    this.high,
    this.low,
    this.close,
    this.prevClose,
    this.volumeLot,
    this.volumeMa20,
    this.stochA,
    this.stochB,
    this.macdA,
    this.macdB,
    this.macdHist,
    this.isIntraday = false,
  });

  final String ticker;
  final DateTime tradeDate;
  final int? open;
  final int? high;
  final int? low;
  final int? close;
  final int? prevClose;
  final int? volumeLot;
  final int? volumeMa20;

  /// Dua garis Stoch RSI dan dua garis MACD, dinamai netral karena legenda
  /// Stockbit belum dipastikan mana K dan D, atau mana MACD dan sinyal.
  final double? stochA;
  final double? stochB;
  final double? macdA;
  final double? macdB;
  final double? macdHist;

  /// True bila hari berjalan: volume dan harga masih bisa berubah.
  final bool isIntraday;

  /// Perubahan harga terhadap penutupan sebelumnya, dalam persen.
  double? get changePercent => switch ((close, prevClose)) {
    (final int c, final int p) when p > 0 => (c - p) / p * 100,
    _ => null,
  };

  /// Volume dibanding rata-rata 20 hari (1,0 = sama).
  double? get volumeRatio => switch ((volumeLot, volumeMa20)) {
    (final int v, final int ma) when ma > 0 => v / ma,
    _ => null,
  };

  /// Hanya `trade_date` dan `ticker` yang wajib; kolom harga dan indikator
  /// boleh kosong karena tidak semua terbaca dari layar sumber.
  factory DailyBar.fromMap(Map<String, dynamic> map) => switch (map) {
    {'ticker': final String ticker, 'trade_date': final String date} =>
      DailyBar(
        ticker: ticker,
        tradeDate: DateTime.parse(date),
        open: _asInt(map['open_price']),
        high: _asInt(map['high_price']),
        low: _asInt(map['low_price']),
        close: _asInt(map['close_price']),
        prevClose: _asInt(map['prev_close']),
        volumeLot: _asInt(map['volume_lot']),
        volumeMa20: _asInt(map['volume_ma20']),
        stochA: _asDouble(map['stoch_rsi_a']),
        stochB: _asDouble(map['stoch_rsi_b']),
        macdA: _asDouble(map['macd_a']),
        macdB: _asDouble(map['macd_b']),
        macdHist: _asDouble(map['macd_hist']),
        isIntraday: map['is_intraday'] as bool? ?? false,
      ),
    _ => throw FormatException('Baris harian tidak valid: $map'),
  };
}

/// Supabase mengirim kolom numeric sebagai angka, tetapi bisa juga teks
/// (mis. lewat pembulatan di sisi server), jadi dua bentuk diterima.
int? _asInt(Object? value) => switch (value) {
  final num n => n.toInt(),
  final String s => num.tryParse(s)?.toInt(),
  _ => null,
};

double? _asDouble(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};

/// Bar terbaru per saham dari kumpulan bar beberapa saham.
Map<String, DailyBar> latestBarPerTicker(Iterable<DailyBar> bars) {
  final latest = <String, DailyBar>{};
  for (final bar in bars) {
    final current = latest[bar.ticker];
    if (current == null || bar.tradeDate.isAfter(current.tradeDate)) {
      latest[bar.ticker] = bar;
    }
  }
  return latest;
}

/// Dari baris yang urut terbaru lebih dulu, simpan satu baris per tanggal
/// (yang paling baru ditangkap), ambil [limit] tanggal terakhir, lalu balik
/// urutannya menjadi dari yang terlama untuk digambar.
List<DailyBar> oneBarPerDate(Iterable<DailyBar> newestFirst, {int? limit}) {
  final seen = <DateTime>{};
  final kept = <DailyBar>[];
  for (final bar in newestFirst) {
    if (seen.add(bar.tradeDate)) kept.add(bar);
  }
  final recent = limit == null ? kept : kept.take(limit).toList();
  return recent.reversed.toList();
}
