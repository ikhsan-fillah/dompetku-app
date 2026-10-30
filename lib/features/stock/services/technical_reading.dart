import '../models/daily_bar.dart';

/// Posisi Stoch RSI terhadap batas 20 dan 80 yang umum dipakai.
enum StochZone { oversold, neutral, overbought }

/// Posisi dua garis MACD terhadap garis nol.
enum MacdSide { bothAbove, bothBelow, mixed }

/// Volume hari itu dibanding rata-rata 20 hari.
enum VolumeLevel { farAbove, above, below, farBelow }

/// Posisi garis pertama terhadap garis kedua (K terhadap D, MACD terhadap
/// sinyal).
enum LineOrder { above, below, equal }

/// Besar histogram MACD dibanding hari sebelumnya. Di Stockbit batang yang
/// membesar digambar pekat dan yang mengecil pudar.
enum HistTrend { growing, shrinking }

/// Pembacaan teknikal yang hanya menyebut posisi angka, tanpa menyimpulkan
/// arah harga. Aturan batasnya sengaja sederhana supaya bisa dicek ulang.
abstract final class TechnicalReading {
  static StochZone? stochZone(double? value) => switch (value) {
    null => null,
    <= 20 => StochZone.oversold,
    >= 80 => StochZone.overbought,
    _ => StochZone.neutral,
  };

  /// Posisi gabungan kedua garis; null bila salah satunya kosong.
  static MacdSide? macdSide(DailyBar bar) => switch ((bar.macdA, bar.macdB)) {
    (final double a, final double b) when a > 0 && b > 0 => MacdSide.bothAbove,
    (final double a, final double b) when a < 0 && b < 0 => MacdSide.bothBelow,
    (double _, double _) => MacdSide.mixed,
    _ => null,
  };

  /// Posisi [first] terhadap [second]; null bila salah satunya kosong.
  static LineOrder? lineOrder(double? first, double? second) =>
      switch ((first, second)) {
        (final double a, final double b) when a > b => LineOrder.above,
        (final double a, final double b) when a < b => LineOrder.below,
        (double _, double _) => LineOrder.equal,
        _ => null,
      };

  /// Membesar bila nilai mutlak histogram hari ini tidak lebih kecil dari
  /// kemarin. Tanpa kemarin dianggap membesar, sama seperti batang pertama
  /// di chart.
  static HistTrend? histTrend(double? today, double? yesterday) =>
      switch ((today, yesterday)) {
        (null, _) => null,
        (final double t, final double y) when t.abs() < y.abs() =>
          HistTrend.shrinking,
        _ => HistTrend.growing,
      };

  static VolumeLevel? volumeLevel(double? ratio) => switch (ratio) {
    null => null,
    >= 1.5 => VolumeLevel.farAbove,
    >= 1 => VolumeLevel.above,
    >= 0.5 => VolumeLevel.below,
    _ => VolumeLevel.farBelow,
  };
}
