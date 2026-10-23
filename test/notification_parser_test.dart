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

  test('BRImo dana keluar dikenali sebagai pengeluaran', () {
    final result = parser.parse(
      'id.co.bri.brimo',
      'Sobat BRI! Dana Rp1.500 keluar dari rekening 675301021460535 pada 20/10/2026 16:56:30',
    );

    expect(result, isNotNull);
    expect(result!.source, 'BRImo');
    expect(result.amount, 1500);
    expect(result.isExpense, isTrue);
  });

  test('nominal saldo tidak diambil sebagai nominal transaksi', () {
    final result = parser.parse(
      'id.co.bri.brimo',
      'Saldo Rp9.000.000. Dana Rp1.500 keluar dari rekening 6753',
    );

    expect(result, isNotNull);
    expect(result!.amount, 1500);
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
    expect(parser.parse('id.dana', 'Pembayaran berhasil'), isNull);
  });

  test('dedupe: key memakai waktu posting persis', () {
    final a = DraftDedupe.keyFor(
      source: 'GoPay',
      amount: 15000,
      detectedAt: DateTime.utc(2026, 9, 1, 10, 4, 59),
    );
    final same = DraftDedupe.keyFor(
      source: 'GoPay',
      amount: 15000,
      detectedAt: DateTime.utc(2026, 9, 1, 10, 4, 59),
    );
    final later = DraftDedupe.keyFor(
      source: 'GoPay',
      amount: 15000,
      detectedAt: DateTime.utc(2026, 9, 1, 10, 5, 1),
    );

    expect(a, same);
    expect(a, isNot(later));
  });

  test('transaksi netral dengan saldo tidak dianggap pengeluaran', () {
    expect(
      parser.parse(
        'id.co.bca.mobile',
        'Transaksi berhasil. Saldo Rp 2.500.000',
      ),
      isNull,
    );
  });

  test('ke rekening bukan nama merchant', () {
    final result = parser.parse(
      'id.co.bri.brimo',
      'Transfer keluar Rp 50.000 ke rekening 1234567890',
    );

    expect(result, isNotNull);
    expect(result!.merchant, isNull);
  });

  test('merchant dipotong di kata penghubung berikutnya', () {
    final result = parser.parse(
      'com.gojek.gopay',
      'Pembayaran berhasil Rp 15.000 ke Warung Kopi pada 20/10/2026',
    );

    expect(result!.merchant, 'Warung Kopi');
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
  group('teks notifikasi asli dan app baru', () {
    const parser = NotificationParser();

    test('BRImo dana masuk dari notifikasi asli', () {
      final r = parser.parse(
        'id.co.bri.brimo',
        'BRImo Sobat BRI! Dana Rp2.500.000 masuk ke rekening 675301021460535 '
            'pada 23/10/2026 14:40:13 KET.:ATMLTRPRM 01TEK 000565181',
      )!;
      expect(r.amount, 2500000);
      expect(r.isExpense, isFalse);
    });

    test('GoPay pembayaran dari notifikasi asli', () {
      final r = parser.parse(
        'com.gojek.gopay',
        'Pembayaran berhasil! Mantaap, kamu barusan bayar Rp24.100 ke SPBU 44.552.04 ADS.',
      )!;
      expect(r.amount, 24100);
      expect(r.isExpense, isTrue);
      expect(r.merchant, startsWith('SPBU'));
    });

    test('app baru dikenali dengan nama sumbernya', () {
      final cases = {
        'ovo.id': 'OVO',
        'com.telkom.mwallet': 'LinkAja',
        'id.bmri.livin': "Livin' by Mandiri",
        'src.com.bni': 'BNI Mobile',
        'com.bsm.activity2': 'BSI Mobile',
        'com.bcadigital.blu': 'blu by BCA',
        'id.co.bankbkemobile.digitalbank': 'SeaBank',
        'com.btpn.dc': 'Jenius',
      };
      for (final entry in cases.entries) {
        final r = parser.parse(
          entry.key,
          'Pembayaran Rp50.000 ke Toko Maju berhasil',
        );
        expect(r?.source, entry.value, reason: entry.key);
        expect(r?.amount, 50000);
      }
    });
  });
}
