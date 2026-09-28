import '../constant/app_constant.dart';

/// Stateless rules for biometric failures; persistence belongs to SessionService.
class BiometricLockout {
  const BiometricLockout._();

  static DateTime? lockedUntil({
    required int failureCount,
    required DateTime now,
  }) {
    if (failureCount < AppConstants.maxBiometricFailures) return null;
    return now.add(const Duration(minutes: AppConstants.biometricLockoutMinutes));
  }

  static bool isLockedOut(DateTime? until, {required DateTime now}) =>
      until != null && now.isBefore(until);
}
