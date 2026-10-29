import 'package:get/get.dart';

/// Nilai broker ringkas dengan tanda: +621,8 M, -2,2 T. "M" miliar, "T"
/// triliun. Awalan "≈" untuk nilai yang dibulatkan di layar sumber.
String formatBrokerValue(int idr, {bool signed = true, bool approx = false}) {
  String trim(double v, int digits) =>
      v.toStringAsFixed(digits).replaceAll('.', ',');

  final abs = idr.abs();
  final String body;
  if (abs >= 1000000000000) {
    body = '${trim(abs / 1e12, 2)} ${'T'.tr}';
  } else if (abs >= 1000000000) {
    body = '${trim(abs / 1e9, 1)} ${'M'.tr}';
  } else {
    body = '${trim(abs / 1e6, 1)} ${'jt'.tr}';
  }
  final sign = idr < 0 ? '-' : (signed && idr > 0 ? '+' : '');
  return '${approx ? '≈' : ''}$sign$body';
}

/// Tanggal singkat: 28/10/2026.
String formatShortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
