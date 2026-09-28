import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _kIsRegistered = 'isRegistered';
  static const _kBiometricEnabled = 'biometricEnabled';
  static const _kBiometricFailureCount = 'biometricFailureCount';
  static const _kBiometricLockedUntil = 'biometricLockedUntil';
  static const _kThemeMode = 'themeMode';

  Future<bool> getIsRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsRegistered) ?? false;
  }

  Future<void> setIsRegistered(bool value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsRegistered, value);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
  }

  Future<int> getBiometricFailureCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kBiometricFailureCount) ?? 0;
  }

  Future<void> setBiometricFailureCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBiometricFailureCount, value);
  }

  Future<DateTime?> getBiometricLockedUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kBiometricLockedUntil);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setBiometricLockedUntil(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kBiometricLockedUntil);
    } else {
      await prefs.setString(_kBiometricLockedUntil, value.toUtc().toIso8601String());
    }
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, value);
  }
}
