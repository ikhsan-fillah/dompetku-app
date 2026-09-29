import 'date_range.dart';

/// Label tanggal berbahasa Indonesia untuk app bar dan kartu.
abstract final class DateLabel {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String day(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// 'Hari ini', 'Kemarin', atau tanggal lengkap untuk hari lainnya.
  static String relativeDay(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime.utc(current.year, current.month, current.day);
    final target = DateTime.utc(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return day(date);
  }

  static String range(DateRange range) {
    final start = range.start;
    final end = range.end;
    if (start == end) return day(end);
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} – ${end.day} ${_months[end.month - 1]} ${end.year}';
    }
    if (start.year == end.year) {
      return '${start.day} ${_months[start.month - 1]} – '
          '${end.day} ${_months[end.month - 1]} ${end.year}';
    }
    return '${day(start)} – ${day(end)}';
  }
}
