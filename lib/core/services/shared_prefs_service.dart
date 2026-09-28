import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _kIsRegistered = 'isRegistered';
  static const _kHasPin = 'hasPin';
  static const _kBiometricEnabled = 'biometricEnabled';

  Future<bool> getIsRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsRegistered) ?? false;
  }

  Future<void> setIsRegistered(bool value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsRegistered, value);
  }

  Future<bool> getHasPin() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasPin) ?? false;
  }

  Future<void> setHasPin(bool value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasPin, value);
  }

  Future<bool> getBiometricEnabled() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
  }
}