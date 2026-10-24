import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/services/local_data_reset_service.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../../core/utils/display_name.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../../../core/services/app_haptics.dart';
import '../../widget/home_widget_service.dart';
import '../../recurring/services/recurring_reminders.dart';

class ProfileController extends GetxController {
  ProfileController(
    this._preferences, {
    LocalDataResetService? resetService,
    AuthController? authController,
    void Function(ThemeMode mode)? themeApplier,
    void Function(String code)? languageApplier,
    TransactionRepository? transactions,
  }) : _resetService = resetService,
       _transactions = transactions,
       _authController = authController,
       _themeApplier = themeApplier ?? Get.changeThemeMode,
       _languageApplier = languageApplier ?? _applyLanguage;

  static const autoLockOptions = [0, 60, 300, 900];
  static const themeOptions = ['light', 'dark'];
  static const defaultThemeMode = 'light';

  final SharedPrefsService _preferences;
  final LocalDataResetService? _resetService;
  final AuthController? _authController;
  final TransactionRepository? _transactions;
  final void Function(ThemeMode mode) _themeApplier;
  final void Function(String code) _languageApplier;
  final biometricEnabled = false.obs;
  final themeMode = defaultThemeMode.obs;
  final language = AppLanguage.defaultCode.obs;

  /// Getaran halus; nilai awal dibaca saat app dibuka (lihat [AppHaptics]).
  final hapticsEnabled = AppHaptics.enabled.obs;

  /// Widget layar utama menyamarkan nominal.
  final widgetHideAmounts = true.obs;

  /// Pengingat harian dan jamnya (menit sejak tengah malam).
  final dailyReminder = true.obs;
  final dailyReminderMinutes = (21 * 60).obs;
  final displayName = ''.obs;

  /// Jumlah semua transaksi tercatat; null sebelum dimuat atau bila gagal.
  final transactionCount = Rxn<int>();
  final autoLockSeconds = 0.obs;
  final savingBiometric = false.obs;
  final savingAutoLock = false.obs;
  final savingTheme = false.obs;
  final savingLanguage = false.obs;
  final resettingData = false.obs;
  final lockingApp = false.obs;
  final error = Rxn<String>();

  static void _applyLanguage(String code) =>
      Get.updateLocale(AppLanguage.localeFor(code));

  String get greetingName => DisplayName.greeting(displayName.value);
  String get initial => DisplayName.initial(displayName.value);

  static ThemeMode themeModeFor(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    biometricEnabled.value = await _preferences.getBiometricEnabled();
    final savedTheme = await _preferences.getThemeMode();
    final selectedTheme = themeOptions.contains(savedTheme)
        ? savedTheme
        : defaultThemeMode;
    themeMode.value = selectedTheme;
    if (savedTheme != selectedTheme) {
      await _preferences.setThemeMode(selectedTheme);
    }
    _themeApplier(themeModeFor(selectedTheme));
    final savedLanguage = await _preferences.getLanguage();
    language.value = AppLanguage.options.contains(savedLanguage)
        ? savedLanguage
        : AppLanguage.defaultCode;
    displayName.value = await _preferences.getDisplayName();
    // Tidak ditunggu: pengaturan widget tidak boleh menahan Profil tampil.
    unawaited(_loadWidgetHideAmounts());
    unawaited(_loadDailyReminder());
    final seconds = await _preferences.getAutoLockSeconds();
    autoLockSeconds.value = autoLockOptions.contains(seconds) ? seconds : 0;
  }

  Future<bool> setThemeMode(String value) async {
    if (!themeOptions.contains(value) || savingTheme.value) return false;
    savingTheme.value = true;
    error.value = null;
    try {
      await _preferences.setThemeMode(value);
      themeMode.value = value;
      _themeApplier(themeModeFor(value));
      return true;
    } catch (_) {
      error.value = 'Gagal menyimpan tema.'.tr;
      return false;
    } finally {
      savingTheme.value = false;
    }
  }

  Future<void> loadTransactionCount() async {
    final repository = _transactions;
    if (repository == null) return;
    try {
      transactionCount.value = await repository.count();
    } catch (_) {
      transactionCount.value = null;
    }
  }

  Future<bool> setLanguage(String value) async {
    if (!AppLanguage.options.contains(value) || savingLanguage.value) {
      return false;
    }
    savingLanguage.value = true;
    error.value = null;
    try {
      await _preferences.setLanguage(value);
      language.value = value;
      _languageApplier(value);
      return true;
    } catch (_) {
      error.value = 'Gagal menyimpan bahasa.'.tr;
      return false;
    } finally {
      savingLanguage.value = false;
    }
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled.value = value;
    AppHaptics.enabled = value;
    if (value) AppHaptics.select();
    try {
      await _preferences.setHapticsEnabled(value);
    } catch (_) {
      error.value = 'Gagal menyimpan pengaturan getaran.'.tr;
    }
  }

  Future<void> _loadWidgetHideAmounts() async {
    try {
      widgetHideAmounts.value = await _preferences.getWidgetHideAmounts();
    } catch (_) {
      // Bawaan tetap disamarkan bila preferensi tidak terbaca.
    }
  }

  Future<void> setWidgetHideAmounts(bool value) async {
    widgetHideAmounts.value = value;
    try {
      await _preferences.setWidgetHideAmounts(value);
      if (Get.isRegistered<HomeWidgetService>()) {
        await Get.find<HomeWidgetService>().update();
      }
    } catch (_) {
      error.value = 'Gagal menyimpan pengaturan widget.'.tr;
    }
  }

  Future<void> _loadDailyReminder() async {
    try {
      dailyReminder.value = await _preferences.getDailyReminderEnabled();
      dailyReminderMinutes.value = await _preferences.getDailyReminderMinutes();
    } catch (_) {
      // Tetap memakai bawaan (aktif, 21.00).
    }
  }

  Future<void> setDailyReminder(bool value) async {
    dailyReminder.value = value;
    try {
      await _preferences.setDailyReminderEnabled(value);
      await _rescheduleReminders(requestPermission: value);
    } catch (_) {
      error.value = 'Gagal menyimpan pengingat.'.tr;
    }
  }

  Future<void> setDailyReminderMinutes(int value) async {
    dailyReminderMinutes.value = value;
    try {
      await _preferences.setDailyReminderMinutes(value);
      await _rescheduleReminders(requestPermission: false);
    } catch (_) {
      error.value = 'Gagal menyimpan pengingat.'.tr;
    }
  }

  Future<void> _rescheduleReminders({required bool requestPermission}) async {
    if (!Get.isRegistered<RecurringReminderService>()) return;
    final reminders = Get.find<RecurringReminderService>();
    if (requestPermission) await reminders.requestPermission();
    await reminders.reschedule();
  }

  Future<void> setDisplayName(String value) async {
    final normalized = DisplayName.normalize(value);
    displayName.value = normalized;
    await _preferences.setDisplayName(normalized);
  }

  Future<bool> setBiometricEnabled(bool value) async {
    if (savingBiometric.value) return false;
    savingBiometric.value = true;
    error.value = null;
    try {
      await _preferences.setBiometricEnabled(value);
      biometricEnabled.value = value;
      return true;
    } catch (_) {
      error.value = 'Gagal menyimpan pengaturan biometrik.'.tr;
      return false;
    } finally {
      savingBiometric.value = false;
    }
  }

  Future<bool> setAutoLockSeconds(int value) async {
    if (!autoLockOptions.contains(value) || savingAutoLock.value) return false;
    savingAutoLock.value = true;
    error.value = null;
    try {
      await _preferences.setAutoLockSeconds(value);
      autoLockSeconds.value = value;
      return true;
    } catch (_) {
      error.value = 'Gagal menyimpan durasi kunci otomatis.'.tr;
      return false;
    } finally {
      savingAutoLock.value = false;
    }
  }

  Future<bool> lockApp() async {
    final authController = _authController;
    if (authController == null || lockingApp.value) return false;

    lockingApp.value = true;
    error.value = null;
    try {
      authController.lock();
      return true;
    } catch (_) {
      error.value = 'Gagal mengunci aplikasi. Coba lagi.'.tr;
      return false;
    } finally {
      lockingApp.value = false;
    }
  }

  Future<bool> resetAllData() async {
    final resetService = _resetService;
    if (resetService == null || resettingData.value) return false;

    resettingData.value = true;
    error.value = null;
    try {
      await resetService.resetAll();
      _authController?.resetSessionState();
      biometricEnabled.value = false;
      themeMode.value = defaultThemeMode;
      _themeApplier(ThemeMode.light);
      language.value = AppLanguage.defaultCode;
      _languageApplier(AppLanguage.defaultCode);
      displayName.value = '';
      autoLockSeconds.value = 0;
      return true;
    } catch (_) {
      error.value = 'Gagal menghapus semua data. Coba lagi.'.tr;
      return false;
    } finally {
      resettingData.value = false;
    }
  }
}
