import 'package:dompetku_app/core/i18n/app_language.dart';
import 'package:dompetku_app/core/i18n/app_translations.dart';
import 'package:dompetku_app/core/services/app_version.dart';
import 'package:dompetku_app/features/auth/utils/greeting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    Get.fallbackLocale = AppLanguage.localeFor(AppLanguage.indonesian);
    Get.locale = AppLanguage.localeFor(AppLanguage.indonesian);
  });

  tearDown(() {
    Get.locale = null;
    Get.clearTranslations();
  });

  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 10, 22, hour, minute);

  group('sapaan menurut jam', () {
    test('batas tiap bagian hari (Indonesia)', () {
      expect(timeGreeting(at(3, 59)), 'Selamat malam');
      expect(timeGreeting(at(4)), 'Selamat pagi');
      expect(timeGreeting(at(10, 59)), 'Selamat pagi');
      expect(timeGreeting(at(11)), 'Selamat siang');
      expect(timeGreeting(at(14, 59)), 'Selamat siang');
      expect(timeGreeting(at(15)), 'Selamat sore');
      expect(timeGreeting(at(17, 59)), 'Selamat sore');
      expect(timeGreeting(at(18)), 'Selamat malam');
      expect(timeGreeting(at(0)), 'Selamat malam');
    });

    test('mengikuti bahasa Inggris', () {
      Get.locale = AppLanguage.localeFor(AppLanguage.english);

      expect(timeGreeting(at(8)), 'Good morning');
      expect(timeGreeting(at(12)), 'Good afternoon');
      expect(timeGreeting(at(16)), 'Good evening');
      expect(timeGreeting(at(22)), 'Good night');
    });
  });

  group('versi aplikasi', () {
    test('tampil dari AppVersion, bukan teks tetap', () {
      AppVersion.debugSet('1.1.2');

      expect(
        'Tally @version · tanpa akun · tanpa cloud'.trParams({
          'version': AppVersion.name,
        }),
        'Tally 1.1.2 · tanpa akun · tanpa cloud',
      );
      expect('v@version'.trParams({'version': AppVersion.name}), 'v1.1.2');
    });

    test('mengikuti perubahan versi', () {
      AppVersion.debugSet('1.2.0');

      expect('v@version'.trParams({'version': AppVersion.name}), 'v1.2.0');
    });
  });
}
