import 'package:get/get.dart';

/// Nilai broker ringkas dengan tanda: +621,8 M, -2,2 T. "M" miliar, "T"
/// triliun. Awalan "≈" untuk nilai yang dibulatkan di layar sumber.
String formatBrokerValue(int idr, {bool signed = true, bool approx = false}) {
  if (idr == 0) return '0';
  String trim(double v, int digits) =>
      v.toStringAsFixed(digits).replaceAll('.', ',');

  final abs = idr.abs();
  final body = switch (abs) {
    >= 1000000000000 => '${trim(abs / 1e12, 2)} ${'T'.tr}',
    >= 1000000000 => '${trim(abs / 1e9, 1)} ${'M'.tr}',
    _ => '${trim(abs / 1e6, 1)} ${'jt'.tr}',
  };
  final sign = switch (idr) {
    < 0 => '-',
    > 0 when signed => '+',
    _ => '',
  };
  return '${approx ? '≈' : ''}$sign$body';
}

/// Tanggal singkat: 28/10/2026.
String formatShortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
