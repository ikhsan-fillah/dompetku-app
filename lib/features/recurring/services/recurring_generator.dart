import '../models/recurring_rule.dart';

/// Menentukan tanggal tagihan yang jatuh tempo dan belum dibuat. Tanpa I/O.
class RecurringGenerator {
  const RecurringGenerator();

  /// Tanggal jatuh tempo dari [rule.startDate] sampai [today] (inklusif),
  /// yang belum tercatat di [rule.lastGeneratedOn].
  List<DateTime> dueOn(RecurringRule rule, DateTime today) {
    if (!rule.isActive) return const [];
    final end = DateTime(today.year, today.month, today.day);
    final after = rule.lastGeneratedOn == null
        ? null
        : _day(rule.lastGeneratedOn!);
    final dues = <DateTime>[];
    for (final date in _occurrences(rule, end)) {
      if (after != null && !date.isAfter(after)) continue;
      dues.add(date);
    }
    return dues;
  }

  /// Tanggal transaksi berikutnya pada atau setelah [from], atau null bila
  /// tidak ada dalam setahun ke depan.
  DateTime? nextOn(RecurringRule rule, DateTime from) {
    final day = _day(from);
    for (final date in _occurrences(rule, day.add(const Duration(days: 400)))) {
      if (!date.isBefore(day)) return date;
    }
    return null;
  }

  Iterable<DateTime> _occurrences(RecurringRule rule, DateTime end) sync* {
    final start = _day(rule.startDate);
    switch (rule.frequency) {
      case RecurringFrequency.weekly:
        final weekday = rule.weekday ?? start.weekday;
        var cursor = start;
        while (cursor.weekday != weekday) {
          cursor = cursor.add(const Duration(days: 1));
        }
        while (!cursor.isAfter(end)) {
          yield cursor;
          cursor = cursor.add(const Duration(days: 7));
        }
      case RecurringFrequency.monthly:
        final day = rule.dayOfMonth ?? start.day;
        var year = start.year;
        var month = start.month;
        while (true) {
          final date = _clampedDate(year, month, day);
          if (date.isAfter(end)) break;
          if (!date.isBefore(start)) yield date;
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
      case RecurringFrequency.yearly:
        var year = start.year;
        while (true) {
          final date = _clampedDate(year, start.month, start.day);
          if (date.isAfter(end)) break;
          if (!date.isBefore(start)) yield date;
          year++;
        }
    }
  }

  /// Tanggal 31 pada bulan 30 hari jatuh di tanggal terakhir bulan itu.
  DateTime _clampedDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
}
