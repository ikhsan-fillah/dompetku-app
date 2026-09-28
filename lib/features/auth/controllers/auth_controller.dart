import 'package:get/get.dart';
import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/biometric_service.dart';
import 'package:dompetku_app/core/utils/biometric_lockout.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository.dart';

class AuthController extends GetxController {
  AuthController(this._sessionRepository, this._biometricService);

  final SessionRepository _sessionRepository;
  final BiometricService _biometricService;
  late final Future<void> initialization;

  final isRegistered = false.obs;
  final isUnlocked = false.obs;
  final biometricEnabled = false.obs;
  final biometricStatus = BiometricStatus.required.obs;
  final biometricFailureCount = 0.obs;
  final biometricLockedUntil = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    initialization = _loadFlags();
  }

  Future<void> _loadFlags() async {
    final session = await _sessionRepository.read();
    isRegistered.value = session.isRegistered;
    biometricEnabled.value = session.biometricEnabled;
    biometricFailureCount.value = session.biometricFailureCount;
    biometricLockedUntil.value = session.biometricLockedUntil;
    if (isLockedOut) {
      biometricStatus.value = BiometricStatus.lockedOut;
    } else if (biometricLockedUntil.value != null) {
      biometricFailureCount.value = 0;
      biometricLockedUntil.value = null;
      biometricStatus.value = BiometricStatus.required;
      await _sessionRepository.saveBiometricFailureState(count: 0);
    }
  }

  Future<void> markRegistered() async {
    isRegistered.value = true;
    await _sessionRepository.setRegistered(true);
  }

  void lock() => isUnlocked.value = false;
  void unlock() => isUnlocked.value = true;

  bool get isLockedOut => BiometricLockout.isLockedOut(
    biometricLockedUntil.value,
    now: DateTime.now(),
  );

  Future<bool> biometricAvailable() => _biometricService.isAvailable();

  Future<void> setBiometricEnabled(bool value) async {
    biometricEnabled.value = value;
    await _sessionRepository.setBiometricEnabled(value);
  }

  Future<bool> unlockWithBiometric() async {
    final previousLockout = biometricLockedUntil.value;
    if (previousLockout != null && !isLockedOut) {
      biometricFailureCount.value = 0;
      biometricLockedUntil.value = null;
      await _sessionRepository.saveBiometricFailureState(count: 0);
    }
    if (isLockedOut) {
      biometricStatus.value = BiometricStatus.lockedOut;
      return false;
    }
    if (!await biometricAvailable()) {
      biometricStatus.value = BiometricStatus.unavailable;
      return false;
    }

    biometricStatus.value = BiometricStatus.authenticating;
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      biometricFailureCount.value = 0;
      biometricLockedUntil.value = null;
      await _sessionRepository.saveBiometricFailureState(count: 0);
      biometricStatus.value = BiometricStatus.authenticated;
      unlock();
      return true;
    }

    final count = biometricFailureCount.value + 1;
    final until = BiometricLockout.lockedUntil(
      failureCount: count,
      now: DateTime.now(),
    );
    biometricFailureCount.value = count;
    biometricLockedUntil.value = until;
    await _sessionRepository.saveBiometricFailureState(
      count: count,
      lockedUntil: until,
    );
    biometricStatus.value = until == null
        ? BiometricStatus.failed
        : BiometricStatus.lockedOut;
    return false;
  }
}
