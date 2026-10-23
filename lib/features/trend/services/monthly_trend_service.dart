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

  /// Menyusun tren pengeluaran harian untuk [month]. Hanya pengeluaran yang
  /// dihitung, dan transaksi bertanggal setelah hari ini diabaikan.
  MonthlyTrend build(
    Iterable<TransactionModel> transactions,
    DateTime month, {
    DateTime? now,
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
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) continue;
      final date = transaction.transactionDate.toLocal();
      if (date.year != first.year || date.month != first.month) continue;
      if (date.day > elapsed) continue;
      daily[date.day - 1] += transaction.amount;
    }
    return MonthlyTrend(
      month: first,
      daysInMonth: days,
      elapsedDays: elapsed,
      isCurrent: isCurrent,
      daily: daily,
    );
  }

  /// Bulan yang bisa dipilih, urut dari yang terlama: bulan yang punya
  /// transaksi (sampai bulan ini) ditambah bulan ini. Bulan depan tidak ada.
  List<DateTime> availableMonths(
    Iterable<TransactionModel> transactions, {
    DateTime? now,
  }) {
    final current = monthOf(now ?? DateTime.now());
    final months = <DateTime>{current};
    for (final transaction in transactions) {
      final month = monthOf(transaction.transactionDate);
      if (!month.isAfter(current)) months.add(month);
    }
    return months.toList()..sort();
  }
}
