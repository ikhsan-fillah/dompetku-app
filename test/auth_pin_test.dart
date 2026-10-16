import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/biometric_service.dart';
import 'package:dompetku_app/core/services/pin_service.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:dompetku_app/features/auth/models/app_session_model.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionRepository implements SessionRepository {
  AppSessionModel value = const AppSessionModel(
    isRegistered: true,
    biometricEnabled: true,
    biometricFailureCount: 0,
  );

  @override
  Future<AppSessionModel> read() async => value;

  @override
  Future<void> saveBiometricFailureState({
    required int count,
    DateTime? lockedUntil,
  }) async {
    value = AppSessionModel(
      isRegistered: true,
      biometricEnabled: true,
      biometricFailureCount: count,
      biometricLockedUntil: lockedUntil,
    );
  }

  @override
  Future<void> setBiometricEnabled(bool value) async {}

  @override
  Future<void> setRegistered(bool value) async {}
}

class _FakeBiometricService implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate() async => false;
}

class _MemorySecureStorage extends SecureStorageService {
  final Map<String, String> store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    store[key] = value;
  }

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> delete(String key) async {
    store.remove(key);
  }
}

void main() {
  late _FakeSessionRepository repository;
  late PinService pins;
  late AuthController controller;

  setUp(() async {
    repository = _FakeSessionRepository();
    pins = PinService(_MemorySecureStorage());
    await pins.create('123456');
    controller = AuthController(
      repository,
      _FakeBiometricService(),
      pinService: pins,
    );
    controller.onInit();
    await controller.initialization;
  });

  test('PIN benar membuka sesi dan mereset counter', () async {
    repository.value = AppSessionModel(
      isRegistered: true,
      biometricEnabled: true,
      biometricFailureCount: 3,
    );
    await controller.initialization;
    await controller.unlockWithPin('123456');

    expect(controller.isUnlocked.value, isTrue);
    expect(controller.biometricFailureCount.value, 0);
  });

  test('PIN salah menaikkan counter bersama biometrik', () async {
    final ok = await controller.unlockWithPin('000000');

    expect(ok, isFalse);
    expect(controller.isUnlocked.value, isFalse);
    expect(controller.biometricFailureCount.value, 1);
  });

  test('lima kegagalan PIN memicu lockout yang sama dengan biometrik', () async {
    for (var i = 0; i < 5; i++) {
      await controller.unlockWithPin('000000');
    }

    expect(controller.isLockedOut, isTrue);
    expect(controller.biometricStatus.value, BiometricStatus.lockedOut);
    expect(await controller.unlockWithPin('123456'), isFalse);
  });

  test('kegagalan campuran biometrik dan PIN dihitung bersama', () async {
    controller.biometricFailureCount.value = 4;
    repository.value = AppSessionModel(
      isRegistered: true,
      biometricEnabled: true,
      biometricFailureCount: 4,
    );

    await controller.unlockWithPin('000000');

    expect(controller.isLockedOut, isTrue);
  });

  test('unlockWithPin gagal bila PIN belum dibuat', () async {
    final empty = PinService(_MemorySecureStorage());
    final other = AuthController(
      _FakeSessionRepository(),
      _FakeBiometricService(),
      pinService: empty,
    );
    other.onInit();
    await other.initialization;

    expect(await other.unlockWithPin('123456'), isFalse);
    expect(other.isUnlocked.value, isFalse);
  });
}
