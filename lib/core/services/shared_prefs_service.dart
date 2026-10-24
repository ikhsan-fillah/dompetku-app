import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _kIsRegistered = 'isRegistered';
  static const _kBiometricEnabled = 'biometricEnabled';
  static const _kBiometricFailureCount = 'biometricFailureCount';
  static const _kBiometricLockedUntil = 'biometricLockedUntil';
  static const _kThemeMode = 'themeMode';
  static const _kDisplayName = 'displayName';
  static const _kAutoLockSeconds = 'autoLockSeconds';
  static const _kLanguage = 'language';
  static const _kHaptics = 'hapticsEnabled';
  static const _kWidgetHideAmounts = 'widgetHideAmounts';
  static const _kDailyReminder = 'dailyReminderEnabled';
  static const _kDailyReminderMinutes = 'dailyReminderMinutes';
  static const _kLastBackupAt = 'lastBackupAt';

  Future<bool> getIsRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsRegistered) ?? false;
  }

  Future<void> setIsRegistered(bool value) async {
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
      await prefs.setString(
        _kBiometricLockedUntil,
        value.toUtc().toIso8601String(),
      );
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

  Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDisplayName) ?? '';
  }

  Future<void> setDisplayName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, value);
  }

  Future<int> getAutoLockSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAutoLockSeconds) ?? 0;
  }

  Future<void> setAutoLockSeconds(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAutoLockSeconds, value);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguage) ?? 'id';
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
  }

  Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHaptics) ?? true;
  }

  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptics, value);
  }

  /// Widget layar utama menyamarkan nominal (bawaan: ya, karena app dikunci).
  Future<bool> getWidgetHideAmounts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWidgetHideAmounts) ?? true;
  }

  Future<void> setWidgetHideAmounts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWidgetHideAmounts, value);
  }

  /// Pengingat harian "Sudah catat pengeluaran hari ini?" (bawaan: aktif).
  Future<bool> getDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyReminder) ?? true;
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyReminder, value);
  }

  /// Jam pengingat harian dalam menit sejak tengah malam (bawaan 21.00).
  Future<int> getDailyReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_kDailyReminderMinutes) ?? 21 * 60;
    return value.clamp(0, 24 * 60 - 1);
  }

  Future<void> setDailyReminderMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDailyReminderMinutes, value);
  }

  /// Waktu cadangan .tally terakhir dibuat di HP ini.
  Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kLastBackupAt);
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  Future<void> setLastBackupAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBackupAt, value.toUtc().toIso8601String());
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
