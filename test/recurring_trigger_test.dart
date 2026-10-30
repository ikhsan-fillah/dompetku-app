import 'package:dompetku_app/core/services/biometric_service.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:dompetku_app/features/auth/models/app_session_model.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session implements SessionRepository {
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
  }) async {}

  @override
  Future<void> setBiometricEnabled(bool value) async {}

  @override
  Future<void> setRegistered(bool value) async {}
}

class _Bio implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate() async => true;
}

void main() {
  test('unlock biometrik menjalankan hook recurring', () async {
    var runs = 0;
    final controller = AuthController(_Session(), _Bio())
      ..onUnlocked = () async => runs++;
    controller.onInit();
    await controller.initialization;

    await controller.unlockWithBiometric();

    expect(runs, 1);
  });

  test('unlock dengan sesi tanpa biometrik juga menjalankan hook', () async {
    var runs = 0;
    final controller = AuthController(
      _Session()
        ..value = const AppSessionModel(
          isRegistered: true,
          biometricEnabled: false,
          biometricFailureCount: 0,
        ),
      _Bio(),
    )..onUnlocked = () async => runs++;
    controller.onInit();
    await controller.initialization;

    expect(runs, 1);
  });

  test('kegagalan biometrik tidak menjalankan hook', () async {
    var runs = 0;
    final controller = AuthController(_Session(), _FailBio())
      ..onUnlocked = () async => runs++;
    controller.onInit();
    await controller.initialization;

    await controller.unlockWithBiometric();

    expect(runs, 0);
  });
}

class _FailBio implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate() async => false;
}
