import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _kPin = 'pin';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> savePin(String pin) async {
    await _storage.write(key: _kPin, value: pin);
  }

  Future<String?> readPin() async{
    return _storage.read(key: _kPin);
  }

  Future<void> deletePin() async{
    await _storage.delete(key: _kPin);
  }
}