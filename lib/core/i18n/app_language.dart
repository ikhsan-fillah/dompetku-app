import 'dart:ui';

import 'package:get/get.dart';

/// Pilihan bahasa UI. Kunci terjemahan adalah teks Indonesia, jadi bahasa
/// Indonesia tidak butuh peta sendiri dan `'teks'.tr` mengembalikan kuncinya.
abstract final class AppLanguage {
  static const indonesian = 'id';
  static const english = 'en';
  static const options = [indonesian, english];
  static const defaultCode = indonesian;

  static Locale localeFor(String code) =>
      code == english ? const Locale('en', 'US') : const Locale('id', 'ID');

  static bool get isEnglish =>
      (Get.locale?.languageCode ?? defaultCode) == english;

  static const _monthsShort = [
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

  static const _monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String monthShort(int month) => _monthsShort[month - 1].tr;

  static String monthLong(int month) => _monthsLong[month - 1].tr;
}
