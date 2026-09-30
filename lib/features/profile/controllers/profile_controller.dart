import 'package:get/get.dart';

import '../../../core/services/local_data_reset_service.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../../core/utils/display_name.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileController extends GetxController {
  ProfileController(
    this._preferences, {
    LocalDataResetService? resetService,
    AuthController? authController,
  })  : _resetService = resetService,
        _authController = authController;

  final SharedPrefsService _preferences;
  final LocalDataResetService? _resetService;
  final AuthController? _authController;
  final biometricEnabled = false.obs;
  final themeMode = 'system'.obs;
  final displayName = ''.obs;
  final savingBiometric = false.obs;
  final resettingData = false.obs;
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
      return true;
    } catch (_) {
      error.value = 'Gagal menghapus semua data. Coba lagi.';
      return false;
    } finally {
      resettingData.value = false;
    }
  }
}
