import 'package:dompetku_app/features/autodetect/services/notification_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = NotificationParser();

  test('pembayaran GoPay dikenali sebagai pengeluaran', () {
    final result = parser.parse(
      'com.gojek.gopay',
      'Pembayaran berhasil Rp 15.000 ke Warung Kopi',
    );

    expect(result, isNotNull);
    expect(result!.source, 'GoPay');
    expect(result.amount, 15000);
    expect(result.isExpense, isTrue);
  });

  test('OTP diabaikan', () {
    final result = parser.parse(
      'id.co.bca.mobile',
      'Kode OTP Anda Rp 123.456 jangan bagikan',
    );

    expect(result, isNull);
  });

  test('promo diabaikan', () {
    final result = parser.parse(
      'com.shopee.id',
      'Promo spesial! Diskon Rp 50.000 khusus hari ini',
    );

    expect(result, isNull);
  });

  test('app tidak dipantau diabaikan', () {
    final result = parser.parse(
      'com.example.lain',
      'Pembayaran berhasil Rp 15.000',
    );

    expect(result, isNull);
  });

  test('teks tanpa nominal diabaikan', () {
    expect(
      parser.parse('id.dana', 'Pembayaran berhasil'),
      isNull,
    );
  });

  test('dedupe: notifikasi sama dalam jendela 5 menit menghasilkan key sama', () {
    final a = DraftDedupe.keyFor(
      source: 'GoPay',
      amount: 15000,
      detectedAt: DateTime.utc(2026, 9, 1, 10, 0, 10),
    );
    final b = DraftDedupe.keyFor(
      source: 'GoPay',
      amount: 15000,
      detectedAt: DateTime.utc(2026, 9, 1, 10, 3, 30),
    );

    expect(a, b);
  });

  test('dedupe: nominal berbeda menghasilkan key berbeda', () {
    final a = DraftDedupe.keyFor(
      source: 'GoPay',
      amount: 15000,
      detectedAt: DateTime.utc(2026, 9, 1, 10),
    );
    final b = DraftDedupe.keyFor(
      source: 'GoPay',
      amount: 20000,
      detectedAt: DateTime.utc(2026, 9, 1, 10),
    );

    expect(a, isNot(b));
  });
}
