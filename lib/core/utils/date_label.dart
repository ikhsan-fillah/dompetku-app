import 'package:get/get.dart';

import '../i18n/app_language.dart';
import 'date_range.dart';

/// Label tanggal (mengikuti bahasa aplikasi) untuk app bar dan kartu.
abstract final class DateLabel {
  static String _month(int month) => AppLanguage.monthShort(month);

  static String day(DateTime date) =>
      '${date.day} ${_month(date.month)} ${date.year}';

  /// 'Hari ini', 'Kemarin', atau tanggal lengkap untuk hari lainnya.
  static String relativeDay(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime.utc(current.year, current.month, current.day);
    final target = DateTime.utc(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hari ini'.tr;
    if (diff == 1) return 'Kemarin'.tr;
    return day(date);
  }

  static String range(DateRange range) {
    final start = range.start;
    final end = range.end;
    if (start == end) return day(end);
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} – ${end.day} ${_month(end.month)} ${end.year}';
    }
    if (start.year == end.year) {
      return '${start.day} ${_month(start.month)} – '
          '${end.day} ${_month(end.month)} ${end.year}';
    }
    return '${day(start)} – ${day(end)}';
  }
}
