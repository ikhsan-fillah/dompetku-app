import '../../../core/services/shared_prefs_service.dart';
import '../models/app_session_model.dart';
import 'session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._prefs);

  final SharedPrefsService _prefs;

  @override
  Future<AppSessionModel> read() async => AppSessionModel(
        isRegistered: await _prefs.getIsRegistered(),
        biometricEnabled: await _prefs.getBiometricEnabled(),
        biometricFailureCount: await _prefs.getBiometricFailureCount(),
        biometricLockedUntil: await _prefs.getBiometricLockedUntil(),
      );

  @override
  Future<void> setRegistered(bool value) => _prefs.setIsRegistered(value);

  @override
  Future<void> setBiometricEnabled(bool value) => _prefs.setBiometricEnabled(value);

  @override
  Future<void> saveBiometricFailureState({required int count, DateTime? lockedUntil}) async {
    await _prefs.setBiometricFailureCount(count);
    await _prefs.setBiometricLockedUntil(lockedUntil);
  }
}
