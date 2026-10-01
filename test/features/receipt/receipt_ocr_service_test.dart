import 'package:dompetku_app/features/receipt/services/receipt_ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecognizer implements ReceiptTextRecognizer {
  _FakeRecognizer({this.text = '', this.error});

  final String text;
  final Object? error;
  String? lastPath;
  bool disposed = false;

  @override
  Future<String> recognize(String imagePath) async {
    lastPath = imagePath;
    if (error != null) throw error!;
    return text;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('ReceiptOcrService', () {
    test('teks terbaca diurai menjadi usulan transaksi', () async {
      final recognizer = _FakeRecognizer(
        text: 'INDOMARET\n25/09/2026\nTOTAL 34.500\nTUNAI 50.000',
      );
      final service = ReceiptOcrService(recognizer);

      final result = await service.scan('/tmp/struk.jpg');

      expect(recognizer.lastPath, '/tmp/struk.jpg');
      expect(result.status, ReceiptScanStatus.success);
      expect(result.isSuccess, isTrue);
      expect(result.receipt?.merchant, 'INDOMARET');
      expect(result.receipt?.date, DateTime(2026, 9, 25));
      expect(result.receipt?.total, 34500);
      expect(result.rawText, contains('TOTAL 34.500'));
    });

    test('teks kosong atau hanya spasi menghasilkan status empty', () async {
      final service = ReceiptOcrService(_FakeRecognizer(text: '  \n  '));

      final result = await service.scan('/tmp/kosong.jpg');

      expect(result.status, ReceiptScanStatus.empty);
      expect(result.isSuccess, isFalse);
      expect(result.receipt, isNull);
      expect(result.message, isNotNull);
    });

    test('error dari recognizer menghasilkan status failure', () async {
      final service = ReceiptOcrService(
        _FakeRecognizer(error: Exception('mlkit gagal')),
      );

      final result = await service.scan('/tmp/rusak.jpg');

      expect(result.status, ReceiptScanStatus.failure);
      expect(result.receipt, isNull);
      expect(result.message, isNotNull);
    });

    test('struk tidak lengkap tetap sukses dengan field kosong', () async {
      final service = ReceiptOcrService(
        _FakeRecognizer(text: 'TOKO A\nTUNAI 50.000'),
      );

      final result = await service.scan('/tmp/sebagian.jpg');

      expect(result.isSuccess, isTrue);
      expect(result.receipt?.total, isNull);
      expect(result.receipt?.isComplete, isFalse);
    });

    test('dispose diteruskan ke recognizer', () async {
      final recognizer = _FakeRecognizer();
      await ReceiptOcrService(recognizer).dispose();
      expect(recognizer.disposed, isTrue);
    });
  });
}
