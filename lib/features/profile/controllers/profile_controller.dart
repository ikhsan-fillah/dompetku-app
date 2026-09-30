import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/local_data_export_service.dart';
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
    Future<void> Function(String text)? clipboardWriter,
  })  : _resetService = resetService,
        _authController = authController,
        _exportService = exportService,
        _clipboardWriter = clipboardWriter ?? _writeClipboard;

  static const autoLockOptions = [0, 60, 300, 900];

  static Future<void> _writeClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }

  final SharedPrefsService _preferences;
  final LocalDataResetService? _resetService;
  final AuthController? _authController;
  final LocalDataExportService? _exportService;
  final Future<void> Function(String text) _clipboardWriter;
  final biometricEnabled = false.obs;
  final themeMode = 'system'.obs;
  final displayName = ''.obs;
  final autoLockSeconds = 0.obs;
  final savingBiometric = false.obs;
  final savingAutoLock = false.obs;
  final resettingData = false.obs;
  final exportingData = false.obs;
  final exportSuccess = Rxn<String>();
  final exportError = Rxn<String>();
  final error = Rxn<String>();

  String get greetingName => DisplayName.greeting(displayName.value);
  String get initial => DisplayName.initial(displayName.value);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    biometricEnabled.value = await _preferences.getBiometricEnabled();
    themeMode.value = await _preferences.getThemeMode();
    displayName.value = await _preferences.getDisplayName();
    final seconds = await _preferences.getAutoLockSeconds();
    autoLockSeconds.value = autoLockOptions.contains(seconds) ? seconds : 0;
  }

  Future<void> setThemeMode(String value) async {
    themeMode.value = value;
    await _preferences.setThemeMode(value);
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

  /// Mengekspor kategori, transaksi, dan anggaran sebagai JSON ke clipboard.
  /// Data tidak dikirim ke layanan eksternal.
  Future<bool> exportData() async {
    final exportService = _exportService;
    if (exportService == null || exportingData.value) return false;

    exportingData.value = true;
    exportSuccess.value = null;
    exportError.value = null;
    try {
      final json = await exportService.exportJson();
      await _clipboardWriter(json);
      exportSuccess.value =
          'Data berhasil disalin sebagai JSON. Tempel ke aplikasi catatan atau berkas untuk menyimpannya.';
      return true;
    } catch (_) {
      exportError.value = 'Gagal mengekspor data. Coba lagi.';
      return false;
    } finally {
      exportingData.value = false;
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
