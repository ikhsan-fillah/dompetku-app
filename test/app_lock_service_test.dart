import 'package:dompetku_app/core/services/app_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 30, 10);

  test('tanpa event background tidak mengunci', () {
    final service = AppLockService();

    expect(service.shouldLock(start), isFalse);
  });

  test('durasi default mengunci langsung', () {
    final service = AppLockService()..onBackgrounded(start);

    expect(service.shouldLock(start), isTrue);
  });

  test('durasi belum tercapai tidak mengunci', () {
    final service = AppLockService()..onBackgrounded(start);

    expect(
      service.shouldLock(
        start.add(const Duration(seconds: 59)),
        duration: const Duration(minutes: 1),
      ),
      isFalse,
    );
  });

  test('durasi tercapai mengunci', () {
    final service = AppLockService()..onBackgrounded(start);

    expect(
      service.shouldLock(
        start.add(const Duration(minutes: 5)),
        duration: const Duration(minutes: 5),
      ),
      isTrue,
    );
  });

  test('onForegrounded menghapus waktu background', () {
    final service = AppLockService()
      ..onBackgrounded(start)
      ..onForegrounded();

    expect(
      service.shouldLock(
        start.add(const Duration(minutes: 20)),
        duration: const Duration(minutes: 1),
      ),
      isFalse,
    );
  });
}
