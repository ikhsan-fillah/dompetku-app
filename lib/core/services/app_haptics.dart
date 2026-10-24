import 'package:flutter/services.dart';

import 'shared_prefs_service.dart';

/// Getaran halus di momen penting. Bisa dimatikan di Profil; nilainya dibaca
/// sekali saat app dibuka ([load]) supaya pemanggilan tidak perlu menunggu.
abstract final class AppHaptics {
  static bool enabled = true;

  static Future<void> load([SharedPrefsService? prefs]) async {
    enabled = await (prefs ?? SharedPrefsService()).getHapticsEnabled();
  }

  /// Simpan berhasil.
  static void success() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Memilih sesuatu: tanggal, kategori, batang grafik, favorit.
  static void select() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Aksi yang perlu perhatian: konfirmasi hapus, batas terlewati.
  static void warning() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
