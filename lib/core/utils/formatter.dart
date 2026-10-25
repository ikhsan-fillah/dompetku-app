import 'package:get/get.dart';

String formatIdr(int amount) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return '${sign}Rp $grouped';
}

String formatIdrPlain(int amount) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return '$sign$grouped';
}

int? parseIdr(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// Nominal ringkas untuk ruang sempit: 850 rb, 1,58 jt, 2,1 M.
String formatCompactIdr(int value) {
  String trim(double v, int digits) {
    var text = v.toStringAsFixed(digits);
    if (text.contains('.')) {
      text = text
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return text.replaceAll('.', ',');
  }

  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000000) return '$sign${trim(abs / 1e9, 1)} ${'M'.tr}';
  if (abs >= 1000000) return '$sign${trim(abs / 1e6, 2)} ${'jt'.tr}';
  if (abs >= 1000) return '$sign${(abs / 1000).round()} ${'rb'.tr}';
  return '$sign$abs';
}
