import '../models/ml_prediction.dart';
import '../models/price_point.dart';

/// Jendela tetap satu prediksi ML: dimulai dari hari sinyal
/// ([MlPrediction.tradeDate]) dan berjalan [MlPrediction.horizonDays] hari
/// bursa ke depan. Tanggal sinyal tidak ikut bergeser walau hari ini sudah
/// berganti, jadi prediksi lama tetap bisa dibandingkan dengan harga yang
/// akhirnya terjadi.
class PredictionWindow {
  const PredictionWindow({
    required this.signalDate,
    required this.horizonDays,
    required this.realized,
  });

  /// Hari bursa terakhir yang dipakai membuat prediksi (hari ke-0).
  final DateTime signalDate;
  final int horizonDays;

  /// Hari bursa setelah [signalDate] yang sudah ada di riwayat harga, paling
  /// banyak [horizonDays] hari, terlama dulu.
  final List<PricePoint> realized;

  /// Hari bursa dalam jendela yang sudah berjalan, 0 sampai [horizonDays].
  int get elapsed => realized.length;

  /// True bila semua hari jendela sudah punya harga penutupan.
  bool get isComplete => elapsed >= horizonDays;

  /// Hari bursa terakhir jendela, null selama jendela belum genap. Ini hari
  /// yang dipakai pipeline untuk menghitung hasil nyata.
  DateTime? get endDate => isComplete ? realized.last.date : null;

  /// Hari bursa tersisa sampai jendela genap.
  int get remaining => horizonDays - elapsed;

  /// Jendela [prediction] dihitung dari [history] (terlama dulu). Riwayat
  /// kosong atau tertinggal dari tanggal sinyal menghasilkan jendela yang
  /// belum berjalan sama sekali.
  factory PredictionWindow.of(
    MlPrediction prediction,
    List<PricePoint> history,
  ) {
    final signal = dateOnly(prediction.tradeDate);
    final after = <PricePoint>[];
    for (final point in history) {
      if (dateOnly(point.date).isAfter(signal)) {
        after.add(point);
        if (after.length == prediction.horizonDays) break;
      }
    }
    return PredictionWindow(
      signalDate: signal,
      horizonDays: prediction.horizonDays,
      realized: after,
    );
  }
}

/// Riwayat sampai hari sinyal, termasuk hari sinyalnya. Dipakai chart supaya
/// garis harga berhenti di hari sinyal, bukan di hari data terbaru.
List<PricePoint> historyUpTo(List<PricePoint> history, DateTime signalDate) {
  final signal = dateOnly(signalDate);
  return [
    for (final point in history)
      if (!dateOnly(point.date).isAfter(signal)) point,
  ];
}

/// Tanggal tanpa jam, supaya perbandingan tidak terpengaruh zona waktu.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
