import 'package:get/get.dart';

import '../../../core/services/shared_prefs_service.dart';

class ProfileController extends GetxController {
  ProfileController(this._preferences);

  final SharedPrefsService _preferences;
  final biometricEnabled = false.obs;
  final themeMode = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    biometricEnabled.value = await _preferences.getBiometricEnabled();
    themeMode.value = await _preferences.getThemeMode();
  }

  Future<void> setThemeMode(String value) async {
    themeMode.value = value;
    await _preferences.setThemeMode(value);
  }
}
