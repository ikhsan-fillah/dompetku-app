enum DateRangePreset {
  today,
  week,
  month,
  threeMonths,
  yearToDate,
  year,
  allTime,
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

  factory DateRange.fromPreset(DateRangePreset preset, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final start = switch (preset) {
      DateRangePreset.today => today,
      DateRangePreset.week => today.subtract(const Duration(days: 6)),
      DateRangePreset.month => DateTime(today.year, today.month),
      DateRangePreset.threeMonths => DateTime(today.year, today.month - 2),
      DateRangePreset.yearToDate => DateTime(today.year),
      DateRangePreset.year => DateTime(today.year - 1, today.month, today.day),
      DateRangePreset.allTime => DateTime(1970),
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

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1).difference(DateTime(date.year, date.month)).inDays;

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
