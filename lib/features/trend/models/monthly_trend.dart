import 'dart:math' as math;

/// Pengeluaran per hari dalam satu bulan kalender. Panjang bulan (28, 29, 30,
/// atau 31 hari) mengikuti kalender, bukan angka tetap.
class MonthlyTrend {
  const MonthlyTrend({
    required this.month,
    required this.daysInMonth,
    required this.elapsedDays,
    required this.isCurrent,
    required this.daily,
  });

  /// Tanggal 1 pada bulan ini.
  final DateTime month;
  final int daysInMonth;

  /// Hari yang sudah berjalan: hari ini untuk bulan berjalan, selain itu
  /// seluruh bulan. Hari sesudahnya belum punya data.
  final int elapsedDays;
  final bool isCurrent;

  /// Panjangnya [daysInMonth]; hari yang belum berjalan bernilai 0.
  final List<int> daily;

  int get total => daily.fold(0, (sum, value) => sum + value);

  /// Rata-rata per hari yang sudah berjalan.
  double get average => elapsedDays == 0 ? 0 : total / elapsedDays;

  int get peakAmount => daily.fold(0, math.max);

  /// Indeks hari dengan pengeluaran terbesar, atau null bila belum ada.
  int? get peakIndex {
    final peak = peakAmount;
    return peak > 0 ? daily.indexOf(peak) : null;
  }

  /// Apakah bulan masih berjalan dan belum sampai hari terakhir.
  bool get isInProgress => elapsedDays < daysInMonth;

  /// Jarak hari pertama dari Senin (0 = Senin ... 6 = Minggu). Pekan dimulai
  /// hari Senin.
  int get weekOffset => DateTime(month.year, month.month).weekday - 1;

  /// Nomor pekan (0, 1, 2, ...) untuk hari berindeks [index].
  int weekOf(int index) => (index + weekOffset) ~/ 7;

  bool isMonday(int index) => (index + weekOffset) % 7 == 0;
}
