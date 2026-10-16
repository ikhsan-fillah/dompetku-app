import 'package:dompetku_app/core/services/pin_service.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
  late _MemorySecureStorage storage;
  late PinService service;

  setUp(() {
    storage = _MemorySecureStorage();
    service = PinService(storage);
  });

  test('PIN yang benar cocok setelah disimpan', () async {
    await service.create('123456');

    expect(await service.verify('123456'), isTrue);
  });

  test('PIN salah ditolak', () async {
    await service.create('123456');

    expect(await service.verify('654321'), isFalse);
    expect(await service.verify(''), isFalse);
  });

  test('PIN tidak pernah tersimpan dalam bentuk plain', () async {
    await service.create('123456');

    for (final value in storage.store.values) {
      expect(value.contains('123456'), isFalse);
    }
  });

  test('salt berbeda menghasilkan hash berbeda untuk PIN yang sama', () async {
    await service.create('123456');
    final first = Map<String, String>.from(storage.store);

    await service.create('123456');
    final second = Map<String, String>.from(storage.store);

    expect(first.values.join('|'), isNot(second.values.join('|')));
  });

  test('hasPin false sebelum dibuat dan true sesudahnya', () async {
    expect(await service.hasPin(), isFalse);

    await service.create('123456');

    expect(await service.hasPin(), isTrue);
  });

  test('clear menghapus PIN', () async {
    await service.create('123456');

    await service.clear();

    expect(await service.hasPin(), isFalse);
    expect(await service.verify('123456'), isFalse);
  });

  test('create menolak PIN yang bukan 6 digit', () async {
    expect(() => service.create('12345'), throwsArgumentError);
    expect(() => service.create('1234567'), throwsArgumentError);
    expect(() => service.create('12a456'), throwsArgumentError);
  });
}
