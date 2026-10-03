enum DateRangePreset {
  today,
  week,
  month,
  threeMonths,
  yearToDate,
  year,
  allTime,
  currentMonth,
  custom,
}

class DateRange {
  DateRange({required DateTime start, required DateTime end})
    : start = _dateOnly(start),
      end = _dateOnly(end) {
    if (this.start.isAfter(this.end)) {
      throw ArgumentError('Start date cannot be after end date');
    }
  }

  final DateTime start;
  final DateTime end;

  factory DateRange.history({
    required DateTime start,
    required DateTime end,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final normalizedEnd = _dateOnly(end);
    if (normalizedEnd.isAfter(today)) {
      throw ArgumentError('End date cannot be after today');
    }
    return DateRange(start: start, end: normalizedEnd);
  }

  static void validateHistory(DateRange range, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    if (range.end.isAfter(today)) {
      throw ArgumentError('End date cannot be after today');
    }
  }

  factory DateRange.fromPreset(DateRangePreset preset, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final start = switch (preset) {
      DateRangePreset.today => today,
      DateRangePreset.week => today.subtract(const Duration(days: 6)),
      DateRangePreset.month => _subtractMonths(today, 1),
      DateRangePreset.threeMonths => _subtractMonths(today, 3),
      DateRangePreset.yearToDate => DateTime(today.year),
      DateRangePreset.year => _subtractYears(today, 1),
      DateRangePreset.allTime => DateTime(1970),
      DateRangePreset.currentMonth => DateTime(today.year, today.month),
      DateRangePreset.custom => today,
    };
    return DateRange(start: start, end: today);
  }

  bool contains(DateTime value) {
    final date = _dateOnly(value);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  int get dayCount => end.difference(start).inDays + 1;

  DateRange get previousEquivalentPeriod => DateRange(
    start: start.subtract(Duration(days: dayCount)),
    end: start.subtract(const Duration(days: 1)),
  );

  static int daysInMonth(DateTime date) => DateTime(
    date.year,
    date.month + 1,
  ).difference(DateTime(date.year, date.month)).inDays;

  /// Waktu yang tersimpan dalam UTC dibaca sebagai hari di zona waktu lokal,
  /// sehingga transaksi dini hari (misalnya WIB) tidak masuk ke hari sebelumnya.
  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime _subtractMonths(DateTime date, int months) {
    final targetIndex = date.year * 12 + date.month - 1 - months;
    final year = targetIndex ~/ 12;
    final month = targetIndex % 12 + 1;
    final day = date.day.clamp(1, daysInMonth(DateTime(year, month)));
    return DateTime(year, month, day);
  }

  static DateTime _subtractYears(DateTime date, int years) {
    final year = date.year - years;
    final day = date.day.clamp(1, daysInMonth(DateTime(year, date.month)));
    return DateTime(year, date.month, day);
  }
}
