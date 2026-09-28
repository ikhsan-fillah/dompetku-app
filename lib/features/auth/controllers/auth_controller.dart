import 'package:get/get.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';

class AuthController extends GetxController{
  final SharedPrefsService _prefs = Get.find();
  final SecureStorageService _secure = Get.find();

  final isRegistered = false.obs;
  final hasPin = false.obs;
  final isUnlocked = false.obs;
  final biometricEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    isRegistered.value = await _prefs.getIsRegistered();
    hasPin.value = await _prefs.getHasPin();
    biometricEnabled.value = await _prefs.getBiometricEnabled();
  }

  Future<void> markRegistered() async{
    isRegistered.value = true;
    await _prefs.setIsRegistered(true);
  }

  void lock() => isUnlocked.value = false;
  void unlock() => isUnlocked.value = true;

  Future<void> setHasPin(bool value) async{
    hasPin.value = value;
    await _prefs.setHasPin(value);
  }

  Future<void> savePin(String pin) async{
    await _secure.savePin(pin);
    await setHasPin(true);
    unlock();
  }

  Future<bool> verifyPin(String pin) async{
    final saved = await _secure.readPin();
    return saved != null && saved == pin;
  }
} 