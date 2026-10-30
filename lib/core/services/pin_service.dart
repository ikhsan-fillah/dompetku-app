import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'secure_storage_service.dart';

/// PIN cadangan (opsional). Hanya hash dan salt yang disimpan di secure storage.
class PinService {
  PinService(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  static const _kHash = 'pinHash';
  static const _kSalt = 'pinSalt';
  static final _pattern = RegExp(r'^\d{6}$');

  final SecureStorageService _storage;
  final Random _random;

  Future<bool> hasPin() async => (await _storage.read(_kHash)) != null;

  Future<void> create(String pin) async {
    if (!_pattern.hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN harus 6 digit');
    }
    final salt = _randomSalt();
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: _hash(pin, salt));
  }

  Future<bool> verify(String pin) async {
    final salt = await _storage.read(_kSalt);
    final stored = await _storage.read(_kHash);
    if (salt == null || stored == null || !_pattern.hasMatch(pin)) {
      return false;
    }
    return _constantTimeEquals(_hash(pin, salt), stored);
  }

  Future<void> clear() async {
    await _storage.delete(_kHash);
    await _storage.delete(_kSalt);
  }

  String _randomSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String pin, String salt) {
    final digest = sha256.convert(utf8.encode('$salt:$pin'));
    return digest.toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
