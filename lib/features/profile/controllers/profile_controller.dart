import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';

import '../../../core/services/local_data_export_service.dart';
import '../../../core/services/local_export_file_service.dart';
import '../../../core/services/local_data_reset_service.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../../core/utils/display_name.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  ProfileController(
    this._preferences, {
    LocalDataResetService? resetService,
    AuthController? authController,
    LocalDataExportService? exportService,
    LocalExportFileService? exportFileService,
    void Function(ThemeMode mode)? themeApplier,
  }) : _resetService = resetService,
       _authController = authController,
       _exportService = exportService,
       _exportFileService = exportFileService,
       _themeApplier = themeApplier ?? Get.changeThemeMode;

  static const autoLockOptions = [0, 60, 300, 900];
  static const themeOptions = ['system', 'light', 'dark'];

  final SharedPrefsService _preferences;
  final LocalDataResetService? _resetService;
  final AuthController? _authController;
  final LocalDataExportService? _exportService;
  final LocalExportFileService? _exportFileService;
  final void Function(ThemeMode mode) _themeApplier;
  final biometricEnabled = false.obs;
  final themeMode = 'system'.obs;
  final displayName = ''.obs;
  final autoLockSeconds = 0.obs;
  final savingBiometric = false.obs;
  final savingAutoLock = false.obs;
  final savingTheme = false.obs;
  final resettingData = false.obs;
  final exportingData = false.obs;
  final lockingApp = false.obs;
  final exportSuccess = Rxn<String>();
  final exportError = Rxn<String>();
  final error = Rxn<String>();

  String get greetingName => DisplayName.greeting(displayName.value);
  String get initial => DisplayName.initial(displayName.value);

  /// Memetakan nilai tersimpan ke [ThemeMode]; nilai tak dikenal jadi sistem.
  static ThemeMode themeModeFor(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    biometricEnabled.value = await _preferences.getBiometricEnabled();
    final theme = await _preferences.getThemeMode();
    themeMode.value = themeOptions.contains(theme) ? theme : 'system';
    displayName.value = await _preferences.getDisplayName();
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
      error.value = 'Gagal menyimpan tema.';
      return false;
    } finally {
      savingTheme.value = false;
    }
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
      error.value = 'Gagal menyimpan pengaturan biometrik.';
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
      error.value = 'Gagal menyimpan durasi kunci otomatis.';
      return false;
    } finally {
      savingAutoLock.value = false;
    }
  }

  /// Menyiapkan JSON dan membagikannya sebagai berkas lokal.
  Future<bool> exportData() async {
    final exportService = _exportService;
    final exportFileService = _exportFileService;
    if (exportService == null ||
        exportFileService == null ||
        exportingData.value) {
      return false;
    }

    exportingData.value = true;
    exportSuccess.value = null;
    exportError.value = null;
    try {
      final export = await exportService.createExport();
      final result = await exportFileService.shareJson(
        export.json,
        exportedAt: export.exportedAt,
      );
      exportSuccess.value = 'Ekspor berhasil: ${result.fileName}';
      return true;
    } catch (_) {
      exportError.value = 'Gagal mengekspor data. Coba lagi.';
      return false;
    } finally {
      exportingData.value = false;
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
      error.value = 'Gagal mengunci aplikasi. Coba lagi.';
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
      themeMode.value = 'system';
      _themeApplier(ThemeMode.system);
      displayName.value = '';
      autoLockSeconds.value = 0;
      exportSuccess.value = null;
      exportError.value = null;
      return true;
    } catch (_) {
      error.value = 'Gagal menghapus semua data. Coba lagi.';
      return false;
    } finally {
      resettingData.value = false;
    }
  }
}
