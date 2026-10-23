import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan auto-detect: app yang dipantau dan mode simpan otomatis.
class AutoDetectSettings {
  static const _kSaveAuto = 'autoDetectSaveAuto';

  static const monitoredApps = {
    'id.co.bca.mobile',
    'com.gojek.gopay',
    'com.gojek.app',
    'com.shopee.id',
    'id.dana',
    'id.co.bri.brimo',
    'com.jago.digitalBanking',
    'ovo.id',
    'com.telkom.mwallet',
    'id.bmri.livin',
    'src.com.bni',
    'com.bsm.activity2',
    'com.bcadigital.blu',
    'id.co.bankbkemobile.digitalbank',
    'com.btpn.dc',
  };

  Future<Set<String>> getApps() async => monitoredApps;

  Future<bool> getSaveAuto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSaveAuto) ?? false;
  }

  Future<void> setSaveAuto(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSaveAuto, value);
  }
}
