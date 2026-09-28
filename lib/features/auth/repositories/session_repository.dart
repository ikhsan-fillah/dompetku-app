import '../models/app_session_model.dart';

abstract interface class SessionRepository {
  Future<AppSessionModel> read();
  Future<void> setRegistered(bool value);
  Future<void> setBiometricEnabled(bool value);
  Future<void> saveBiometricFailureState({required int count, DateTime? lockedUntil});
}
