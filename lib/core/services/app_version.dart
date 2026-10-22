import 'package:package_info_plus/package_info_plus.dart';

/// Versi aplikasi yang dibaca dari paket terpasang (versionName di
/// `pubspec.yaml`), jadi tampilan versi ikut naik setiap rilis tanpa edit teks.
abstract final class AppVersion {
  static String _name = '';

  /// Nama versi, misalnya `1.1.2`. Kosong sebelum [init] selesai.
  static String get name => _name;

  /// Dipanggil sekali sebelum `runApp`. Gagal membaca tidak menghentikan app.
  static Future<void> init() async {
    try {
      _name = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      _name = '';
    }
  }

  /// Untuk tes.
  static void debugSet(String value) => _name = value;
}
