import 'receipt_parser.dart';

/// Membaca teks dari gambar struk. Dipisah dari plugin agar mudah diuji.
abstract class ReceiptTextRecognizer {
  Future<String> recognize(String imagePath);

  Future<void> dispose();
}

enum ReceiptScanStatus { success, empty, failure }

class ReceiptScanResult {
  const ReceiptScanResult._(
    this.status, {
    this.rawText = '',
    this.receipt,
    this.message,
  });

  factory ReceiptScanResult.success(String rawText, ParsedReceipt receipt) {
    return ReceiptScanResult._(
      ReceiptScanStatus.success,
      rawText: rawText,
      receipt: receipt,
    );
  }

  factory ReceiptScanResult.empty() {
    return const ReceiptScanResult._(
      ReceiptScanStatus.empty,
      message: 'Teks pada struk tidak terbaca. Coba foto yang lebih jelas.',
    );
  }

  factory ReceiptScanResult.failure() {
    return const ReceiptScanResult._(
      ReceiptScanStatus.failure,
      message: 'Gagal membaca struk. Coba lagi atau isi manual.',
    );
  }

  final ReceiptScanStatus status;
  final String rawText;
  final ParsedReceipt? receipt;
  final String? message;

  bool get isSuccess => status == ReceiptScanStatus.success;
}

/// Menjalankan OCR lalu mengurai hasilnya menjadi usulan data transaksi.
/// Tidak menyimpan apa pun; hasilnya harus ditinjau pengguna lebih dulu.
class ReceiptOcrService {
  ReceiptOcrService(
    this._recognizer, {
    ReceiptParser parser = const ReceiptParser(),
  }) : _parser = parser;

  final ReceiptTextRecognizer _recognizer;
  final ReceiptParser _parser;

  Future<ReceiptScanResult> scan(String imagePath) async {
    try {
      final text = (await _recognizer.recognize(imagePath)).trim();
      if (text.isEmpty) return ReceiptScanResult.empty();
      return ReceiptScanResult.success(text, _parser.parse(text));
    } catch (_) {
      return ReceiptScanResult.failure();
    }
  }

  Future<void> dispose() => _recognizer.dispose();
}
