import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/models/watchlist_item.dart';
import 'package:dompetku_app/features/stock/widgets/stock_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBrokerValue', () {
    test('miliar dan triliun memakai koma desimal dan tanda', () {
      expect(formatBrokerValue(621800000000), '+621,8 M');
      expect(formatBrokerValue(-37461200000), '-37,5 M');
      expect(formatBrokerValue(1160600000000), '+1,16 T');
      expect(formatBrokerValue(-2200000000000), '-2,20 T');
    });

    test('nol ditulis 0, nilai kecil dalam jt', () {
      expect(formatBrokerValue(0), '0');
      expect(formatBrokerValue(76400000), '+76,4 jt');
    });

    test('tanpa tanda untuk jumlah beli atau jual, ≈ untuk nilai bulat', () {
      expect(formatBrokerValue(538800000000, signed: false), '538,8 M');
      expect(formatBrokerValue(-2200000000000, approx: true), '≈-2,20 T');
    });
  });

  group('baris dari Supabase', () {
    test('watchlist: kolom wajib hilang gagal keras', () {
      expect(
        () => WatchlistItem.fromMap({'ticker': 'BBCA'}),
        throwsFormatException,
      );
      final item = WatchlistItem.fromMap({
        'ticker': 'BBCA',
        'is_active': false,
        'note': null,
        'created_at': '2026-10-29T08:00:00Z',
      });
      expect(item.isActive, isFalse);
      expect(item.createdAt, isNotNull);
    });

    test(
      'broker: nilai dari Supabase bisa int atau num, kolom hilang gagal',
      () {
        expect(
          () => BrokerRangeRow.fromMap({'ticker': 'BBCA', 'side': 'buy'}),
          throwsFormatException,
        );
        final row = BrokerRangeRow.fromMap({
          'ticker': 'BBCA',
          'range_label': 'Latest',
          'range_start': '2026-10-28',
          'range_end': '2026-10-28',
          'broker_code': 'ZP',
          'side': 'buy',
          'value_idr': 536000000000.0,
        });
        expect(row.valueIdr, 536000000000);
        expect(row.isApprox, isFalse);
      },
    );
  });
}
