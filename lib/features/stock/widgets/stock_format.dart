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

/// Harga saham dengan titik ribuan: 9150 menjadi 9.150.
String formatPrice(int price) => price.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

/// Volume dalam lot, ringkas: 52,3 jt, 840 rb.
String formatLot(int lot) {
  String trim(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
  return switch (lot.abs()) {
    >= 1000000 => '${trim(lot / 1e6)} ${'jt'.tr}',
    >= 1000 => '${trim(lot / 1e3)} ${'rb'.tr}',
    _ => '$lot',
  };
}

/// Persentase dengan tanda: +1,2%, -0,8%.
String formatPercent(double value) {
  final body = value.abs().toStringAsFixed(1).replaceAll('.', ',');
  return switch (value) {
    > 0 => '+$body%',
    < 0 => '-$body%',
    _ => '$body%',
  };
}

/// Nilai indikator dengan koma desimal: 49,3 atau -282,82.
String formatIndicator(double value, {int digits = 2}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

/// Tanggal tanpa tahun: 28/10.
String formatDayMonth(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}';
