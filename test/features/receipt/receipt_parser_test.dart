import 'package:dompetku_app/features/receipt/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();

  group('ReceiptParser', () {
    test('mengurai struk minimarket dan mengabaikan subtotal, tunai, kembali', () {
      const raw = """
ALFAMART CILANDAK
JL. TB SIMATUPANG NO 5
25/09/2026 14:32
SUSU UHT 1 x 18.500 18.500
ROTI TAWAR 1 x 16.000 16.000
SUBTOTAL 34.500
TOTAL 34.500
TUNAI 50.000
KEMBALI 15.500
""";
      final result = parser.parse(raw);
      expect(result.merchant, 'ALFAMART CILANDAK');
      expect(result.date, DateTime(2026, 9, 25));
      expect(result.total, 34500);
      expect(result.isComplete, isTrue);
    });

    test('grand total mengalahkan total biasa', () {
      const raw = """
KOPI KENANGAN
Tgl: 3 Okt 2026
TOTAL 40.000
PPN 11% 4.400
GRAND TOTAL 44.400
""";
      final result = parser.parse(raw);
      expect(result.merchant, 'KOPI KENANGAN');
      expect(result.date, DateTime(2026, 10, 3));
      expect(result.total, 44400);
    });

    test('total di baris berikutnya dan tahun dua digit', () {
      const raw = """
Warung Bu Sri
12-08-26
TOTAL BAYAR
Rp 27.500
""";
      final result = parser.parse(raw);
      expect(result.merchant, 'Warung Bu Sri');
      expect(result.date, DateTime(2026, 8, 12));
      expect(result.total, 27500);
    });

    test('desimal ,00 tidak ikut menjadi digit', () {
      expect(parser.parse('TOTAL 25.000,00').total, 25000);
      expect(ReceiptParser.parseAmountToken('18.500'), 18500);
      expect(ReceiptParser.parseAmountToken('1.250.000'), 1250000);
    });

    test('melewati baris NPWP saat mencari merchant', () {
      final result = parser.parse('NPWP 01.234.567.8-901.000\nINDOMARET');
      expect(result.merchant, 'INDOMARET');
    });

    test('tanggal tidak valid dan teks kosong menghasilkan null', () {
      expect(parser.parse('TOKO A\n31/02/2026').date, isNull);
      final empty = parser.parse('');
      expect(empty.merchant, isNull);
      expect(empty.date, isNull);
      expect(empty.total, isNull);
      expect(empty.isComplete, isFalse);
    });

    test('tanpa kata total, total dibiarkan kosong', () {
      expect(parser.parse('TOKO A\nTUNAI 50.000\nKEMBALI 5.000').total, isNull);
    });
  });
}
