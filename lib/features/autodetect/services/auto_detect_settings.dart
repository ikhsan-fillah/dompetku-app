import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan auto-detect: app yang dipantau dan mode simpan otomatis.
class AutoDetectSettings {
  static const _kApps = 'autoDetectApps';
  static const _kSaveAuto = 'autoDetectSaveAuto';

  static const defaultOff = ['com.whatsapp', 'ovo'];

  Future<Set<String>> getApps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kApps);
    if (raw == null) {
      return const {
        'id.co.bca.mobile',
        'com.gojek.gopay',
        'com.shopee.id',
        'id.dana',
      };
    }
    return Set<String>.from(
      (jsonDecode(raw) as List).cast<String>(),
    );
  }

  Future<void> setApps(Set<String> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApps, jsonEncode(apps.toList()));
  }

  Future<bool> getSaveAuto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSaveAuto) ?? false;
  }

  Future<void> setSaveAuto(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSaveAuto, value);
  }
}
