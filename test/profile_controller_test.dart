import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/services/local_data_reset_service.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSharedPrefsService extends SharedPrefsService {
  bool biometric = false;
  String theme = 'system';
  String name = '';
  int autoLock = 0;
  bool failBiometricWrite = false;
  bool failAutoLockWrite = false;

  @override
  Future<bool> getBiometricEnabled() async => biometric;

  @override
  Future<String> getThemeMode() async => theme;

  @override
  Future<String> getDisplayName() async => name;

  @override
  Future<int> getAutoLockSeconds() async => autoLock;

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

  @override
  Future<void> setAutoLockSeconds(int value) async {
    if (failAutoLockWrite) throw StateError('write failed');
    autoLock = value;
  }
}

class _FakeAppDatabase extends AppDatabase {
  @override
  Future<void> deleteDatabaseFile() async {}
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<void> deleteAll() async {}
}

class _FakeResetService extends LocalDataResetService {
  _FakeResetService()
      : super(
          _FakeAppDatabase(),
          _FakeSharedPrefsService(),
          _FakeSecureStorage(),
        );

  bool fail = false;
  int calls = 0;

  @override
  Future<void> resetAll() async {
    calls++;
    if (fail) throw StateError('reset failed');
  }
}

void main() {
  late _FakeSharedPrefsService preferences;
  late _FakeResetService resetService;
  late ProfileController controller;

  setUp(() {
    preferences = _FakeSharedPrefsService();
    resetService = _FakeResetService();
    controller = ProfileController(preferences, resetService: resetService);
  });

  test('load membaca preferensi profil', () async {
    preferences.biometric = true;
    preferences.theme = 'light';
    preferences.name = '  Ikhsan  ';
    preferences.autoLock = 300;

    await controller.load();

    expect(controller.biometricEnabled.value, isTrue);
    expect(controller.themeMode.value, 'light');
    expect(controller.displayName.value, '  Ikhsan  ');
    expect(controller.autoLockSeconds.value, 300);
  });

  test('load memakai nilai langsung untuk durasi tidak valid', () async {
    preferences.autoLock = 42;

    await controller.load();

    expect(controller.autoLockSeconds.value, 0);
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

  test('setAutoLockSeconds menyimpan durasi yang valid', () async {
    final saved = await controller.setAutoLockSeconds(60);

    expect(saved, isTrue);
    expect(preferences.autoLock, 60);
    expect(controller.autoLockSeconds.value, 60);
    expect(controller.savingAutoLock.value, isFalse);
    expect(controller.error.value, isNull);
  });

  test('setAutoLockSeconds menolak durasi yang tidak tersedia', () async {
    final saved = await controller.setAutoLockSeconds(42);

    expect(saved, isFalse);
    expect(preferences.autoLock, 0);
    expect(controller.autoLockSeconds.value, 0);
  });

  test('setAutoLockSeconds menangani kegagalan penyimpanan', () async {
    preferences.failAutoLockWrite = true;

    final saved = await controller.setAutoLockSeconds(300);

    expect(saved, isFalse);
    expect(controller.autoLockSeconds.value, 0);
    expect(controller.savingAutoLock.value, isFalse);
    expect(
      controller.error.value,
      'Gagal menyimpan durasi kunci otomatis.',
    );
  });

  test('resetAllData menghapus data dan mengatur ulang state profil', () async {
    controller.biometricEnabled.value = true;
    controller.themeMode.value = 'dark';
    controller.displayName.value = 'Ikhsan';
    controller.autoLockSeconds.value = 900;

    final reset = await controller.resetAllData();

    expect(reset, isTrue);
    expect(resetService.calls, 1);
    expect(controller.biometricEnabled.value, isFalse);
    expect(controller.themeMode.value, 'system');
    expect(controller.displayName.value, isEmpty);
    expect(controller.autoLockSeconds.value, 0);
    expect(controller.resettingData.value, isFalse);
    expect(controller.error.value, isNull);
  });

  test('resetAllData menangani kegagalan reset', () async {
    resetService.fail = true;

    final reset = await controller.resetAllData();

    expect(reset, isFalse);
    expect(resetService.calls, 1);
    expect(controller.resettingData.value, isFalse);
    expect(controller.error.value, 'Gagal menghapus semua data. Coba lagi.');
  });

  test('resetAllData gagal tanpa layanan reset', () async {
    final controllerWithoutReset = ProfileController(preferences);

    final reset = await controllerWithoutReset.resetAllData();

    expect(reset, isFalse);
  });
}
