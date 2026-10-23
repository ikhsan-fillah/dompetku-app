import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';
import '../../transaction/models/transaction_model.dart';
import '../models/monthly_trend.dart';

class MonthlyTrendService {
  const MonthlyTrendService();

  /// Tanggal 1 pada bulan (waktu lokal) dari [value].
  static DateTime monthOf(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month);
  }

  /// Menyusun tren harian untuk [month]. Hanya transaksi berjenis [type]
  /// (bawaan pengeluaran) yang dihitung, dan transaksi bertanggal setelah hari
  /// ini diabaikan.
  MonthlyTrend build(
    Iterable<TransactionModel> transactions,
    DateTime month, {
    DateTime? now,
    TransactionType type = TransactionType.expense,
  }) {
    final today = (now ?? DateTime.now()).toLocal();
    final first = DateTime(month.year, month.month);
    final days = DateRange.daysInMonth(first);
    final current = monthOf(today);
    final isCurrent = first == current;
    final elapsed = first.isAfter(current)
        ? 0
        : isCurrent
        ? today.day
        : days;

    final daily = List<int>.filled(days, 0);
    var count = 0;
    for (final transaction in transactions) {
      if (transaction.type != type) continue;
      final date = transaction.transactionDate.toLocal();
      if (date.year != first.year || date.month != first.month) continue;
      if (date.day > elapsed) continue;
      daily[date.day - 1] += transaction.amount;
      count++;
    }
    return MonthlyTrend(
      month: first,
      daysInMonth: days,
      elapsedDays: elapsed,
      isCurrent: isCurrent,
      daily: daily,
      type: type,
      transactionCount: count,
    );
  }

  /// Rentang satu bulan penuh (tanggal 1 sampai hari terakhir).
  static DateRange monthRange(DateTime month) => DateRange(
    start: DateTime(month.year, month.month),
    end: DateTime(month.year, month.month + 1, 0),
  );

  /// Semua bulan dari bulan transaksi pertama sampai bulan ini, urut dari yang
  /// terlama. Pemanggil memeriksa mana yang punya transaksi. Tanpa transaksi
  /// (atau tanggal pertama di masa depan) hanya bulan ini yang dikembalikan.
  List<DateTime> candidateMonths(DateTime? firstTransaction, {DateTime? now}) {
    final current = monthOf(now ?? DateTime.now());
    if (firstTransaction == null) return [current];
    var month = monthOf(firstTransaction);
    if (month.isAfter(current)) return [current];
    final months = <DateTime>[];
    while (!month.isAfter(current)) {
      months.add(month);
      month = DateTime(month.year, month.month + 1);
    }
    return months;
  }
}
