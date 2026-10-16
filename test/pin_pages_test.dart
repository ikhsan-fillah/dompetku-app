import 'package:dompetku_app/core/services/pin_service.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:dompetku_app/features/auth/pages/pin_create_page.dart';
import 'package:flutter/material.dart';
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

Future<void> _tapDigits(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
}

void main() {
  testWidgets('Create PIN meminta konfirmasi dan menyimpan PIN yang cocok', (
    tester,
  ) async {
    final pins = PinService(_MemorySecureStorage());
    var created = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PinCreatePage(pinService: pins, onCreated: () => created = true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create a PIN'), findsOneWidget);
    await _tapDigits(tester, '123456');
    await tester.pumpAndSettle();

    expect(find.text('Confirm your PIN'), findsOneWidget);
    await _tapDigits(tester, '123456');
    await tester.pumpAndSettle();

    expect(created, isTrue);
    expect(await pins.hasPin(), isTrue);
    expect(await pins.verify('123456'), isTrue);
  });

  testWidgets('PIN konfirmasi tidak cocok kembali ke langkah pertama', (
    tester,
  ) async {
    final pins = PinService(_MemorySecureStorage());
    var created = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PinCreatePage(pinService: pins, onCreated: () => created = true),
      ),
    );
    await tester.pumpAndSettle();

    await _tapDigits(tester, '123456');
    await tester.pumpAndSettle();
    await _tapDigits(tester, '654321');
    await tester.pumpAndSettle();

    expect(find.text("PINs don't match. Try again."), findsOneWidget);
    expect(find.text('Create a PIN'), findsOneWidget);
    expect(created, isFalse);
    expect(await pins.hasPin(), isFalse);
  });

  testWidgets('keypad tidak memiliki tombol 000', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PinCreatePage(
          pinService: PinService(_MemorySecureStorage()),
          onCreated: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('000'), findsNothing);
    for (final digit in ['0', '1', '9']) {
      expect(find.text(digit), findsOneWidget);
    }
  });
}
