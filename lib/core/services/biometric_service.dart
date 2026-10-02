import 'package:local_auth/local_auth.dart';

abstract interface class BiometricService {
  Future<bool> isAvailable();
  Future<bool> authenticate();
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _localAuthentication.canCheckBiometrics &&
          await _localAuthentication.isDeviceSupported();
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Autentikasi untuk membuka DompetKu',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
