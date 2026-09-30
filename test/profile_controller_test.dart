import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSharedPrefsService extends SharedPrefsService {
  bool biometric = false;
  String theme = 'system';
  String name = '';
  bool failBiometricWrite = false;

  @override
  Future<bool> getBiometricEnabled() async => biometric;

  @override
  Future<String> getThemeMode() async => theme;

  @override
  Future<String> getDisplayName() async => name;

  @override
  Future<void> setBiometricEnabled(bool value) async {
    if (failBiometricWrite) throw StateError('write failed');
    biometric = value;
  }

  @override
  Future<void> setThemeMode(String value) async {
    theme = value;
  }

  @override
  Future<void> setDisplayName(String value) async {
    name = value;
  }
}

void main() {
  late _FakeSharedPrefsService preferences;
  late ProfileController controller;

  setUp(() {
    preferences = _FakeSharedPrefsService();
    controller = ProfileController(preferences);
  });

  test('load membaca preferensi profil', () async {
    preferences.biometric = true;
    preferences.theme = 'light';
    preferences.name = '  Ikhsan  ';

    await controller.load();

    expect(controller.biometricEnabled.value, isTrue);
    expect(controller.themeMode.value, 'light');
    expect(controller.displayName.value, '  Ikhsan  ');
  });

  test('setBiometricEnabled menyimpan dan memperbarui state', () async {
    final saved = await controller.setBiometricEnabled(true);

    expect(saved, isTrue);
    expect(preferences.biometric, isTrue);
    expect(controller.biometricEnabled.value, isTrue);
    expect(controller.savingBiometric.value, isFalse);
    expect(controller.error.value, isNull);
  });

  test('setBiometricEnabled menyimpan nilai false', () async {
    preferences.biometric = true;
    controller.biometricEnabled.value = true;

    final saved = await controller.setBiometricEnabled(false);

    expect(saved, isTrue);
    expect(preferences.biometric, isFalse);
    expect(controller.biometricEnabled.value, isFalse);
  });

  test('setBiometricEnabled menangani kegagalan penyimpanan', () async {
    preferences.failBiometricWrite = true;

    final saved = await controller.setBiometricEnabled(true);

    expect(saved, isFalse);
    expect(controller.biometricEnabled.value, isFalse);
    expect(controller.savingBiometric.value, isFalse);
    expect(controller.error.value, 'Gagal menyimpan pengaturan biometrik.');
  });

  test('setDisplayName menormalisasi lalu menyimpan nama', () async {
    await controller.setDisplayName('  Ikhsan   Fillah  ');

    expect(controller.displayName.value, 'Ikhsan Fillah');
    expect(preferences.name, 'Ikhsan Fillah');
    expect(controller.greetingName, 'Ikhsan Fillah');
    expect(controller.initial, 'I');
  });

  test('setThemeMode menyimpan preferensi tema', () async {
    await controller.setThemeMode('light');

    expect(controller.themeMode.value, 'light');
    expect(preferences.theme, 'light');
  });
}
