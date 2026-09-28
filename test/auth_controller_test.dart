import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/app_lock_service.dart';
import 'package:dompetku_app/core/services/biometric_service.dart';
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
  _FakeBiometricService({this.result = false});

  final bool result;

  @override
  Future<bool> authenticate() async => result;

  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  test('five unsuccessful biometric attempts create a lockout', () async {
    final controller = AuthController(
      _FakeSessionRepository(),
      _FakeBiometricService(),
    );
    controller.onInit();
    await controller.initialization;

    for (var index = 0; index < 5; index++) {
      await controller.unlockWithBiometric();
    }

    expect(controller.biometricStatus.value, BiometricStatus.lockedOut);
    expect(controller.biometricFailureCount.value, 5);
    expect(controller.isUnlocked.value, isFalse);
  });

  test(
    'successful biometric authentication clears persisted failures',
    () async {
      final repository = _FakeSessionRepository();
      final controller = AuthController(
        repository,
        _FakeBiometricService(result: true),
      );
      controller.onInit();
      await controller.initialization;

      expect(await controller.unlockWithBiometric(), isTrue);
      expect(controller.biometricFailureCount.value, 0);
      expect(controller.isUnlocked.value, isTrue);
    },
  );

  test('an expired lockout resets failures before a new attempt', () async {
    final repository = _FakeSessionRepository()
      ..value = AppSessionModel(
        isRegistered: true,
        biometricEnabled: true,
        biometricFailureCount: 5,
        biometricLockedUntil: DateTime.now().subtract(
          const Duration(minutes: 1),
        ),
      );
    final controller = AuthController(repository, _FakeBiometricService());
    controller.onInit();
    await controller.initialization;

    await controller.unlockWithBiometric();

    expect(controller.biometricFailureCount.value, 1);
    expect(controller.biometricStatus.value, BiometricStatus.failed);
  });

  test('app locks as soon as it returns from background by default', () {
    final service = AppLockService();
    final time = DateTime(2026, 9, 28, 10);
    service.onBackgrounded(time);
    expect(service.shouldLock(time), isTrue);
  });
}
