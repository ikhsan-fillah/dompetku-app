import 'package:dompetku_app/features/stock/models/broker_group.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/services/broker_group_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

BrokerRangeRow row(
  String code,
  BrokerSide side,
  double billions, {
  String label = 'Latest',
  DateTime? end,
  bool approx = false,
}) => BrokerRangeRow(
  ticker: 'BBCA',
  rangeLabel: label,
  rangeStart: end ?? DateTime(2026, 10, 28),
  rangeEnd: end ?? DateTime(2026, 10, 28),
  brokerCode: code,
  side: side,
  valueIdr: (billions * 1e9).round(),
  isApprox: approx,
);

const rules = BrokerGroupRules({
  'XL': BrokerGroup.ritel,
  'XC': BrokerGroup.ritel,
  'PD': BrokerGroup.ritel,
  'IF': BrokerGroup.bandar,
  'SQ': BrokerGroup.bandar,
  'ZP': BrokerGroup.asing,
  'CC': BrokerGroup.asing,
});

void main() {
  const calculator = BrokerGroupCalculator();

  test('net kelompok = jumlah beli dikurangi jumlah jual', () {
    final summary = calculator.summarize([
      row('XL', BrokerSide.sell, 189.3),
      row('XC', BrokerSide.sell, 59.5),
      row('PD', BrokerSide.sell, 53.1),
      row('IF', BrokerSide.buy, 82.4),
      row('SQ', BrokerSide.sell, 120),
      row('ZP', BrokerSide.buy, 536),
      row('CC', BrokerSide.sell, 468.3),
    ], rules);

    expect(summary.of(BrokerGroup.ritel).netIdr, -301900000000);
    expect(summary.of(BrokerGroup.ritel).sellIdr, 301900000000);
    expect(summary.of(BrokerGroup.ritel).buyIdr, 0);
    expect(summary.of(BrokerGroup.bandar).netIdr, -37600000000);
    expect(summary.of(BrokerGroup.asing).netIdr, 67700000000);
    expect(summary.of(BrokerGroup.ritel).brokerCount, 3);
  });

  test('broker di luar aturan masuk belum diklasifikasi, bukan kelompok', () {
    final summary = calculator.summarize([
      row('YP', BrokerSide.sell, 149.6),
      row('ZP', BrokerSide.buy, 10),
    ], rules);

    expect(summary.unclassified.netIdr, -149600000000);
    expect(summary.unclassified.brokerCount, 1);
    expect(summary.of(BrokerGroup.asing).netIdr, 10000000000);
    expect(summary.of(BrokerGroup.ritel).brokerCount, 0);
  });

  test('nilai yang dibulatkan di layar sumber ditandai di kelompoknya', () {
    final summary = calculator.summarize([
      row('CC', BrokerSide.sell, 2200, approx: true),
      row('ZP', BrokerSide.buy, 221.5),
    ], rules);

    expect(summary.of(BrokerGroup.asing).hasApprox, isTrue);
    expect(summary.of(BrokerGroup.asing).approxCount, 1);
    expect(summary.of(BrokerGroup.bandar).hasApprox, isFalse);
  });

  test('tanpa baris, semua kelompok nol', () {
    final summary = calculator.summarize(const [], rules);

    for (final group in BrokerGroup.values) {
      expect(summary.of(group).netIdr, 0);
      expect(summary.of(group).brokerCount, 0);
    }
    expect(summary.unclassified.brokerCount, 0);
  });

  group('BrokerGroupRules', () {
    test('membaca baris broker_group dan melewati kelompok tak dikenal', () {
      final parsed = BrokerGroupRules.fromRows([
        {'broker_code': 'xl', 'grp': 'ritel'},
        {'broker_code': 'AZ', 'grp': 'bandar'},
        {'broker_code': 'ZP', 'grp': 'asing'},
        {'broker_code': 'DR', 'grp': 'belum_diklasifikasi'},
        {'broker_code': 'ZZ', 'grp': 'baik'},
      ]);

      expect(parsed.groupOf('XL'), BrokerGroup.ritel);
      expect(parsed.groupOf('AZ'), BrokerGroup.bandar);
      expect(parsed.groupOf('ZP'), BrokerGroup.asing);
      expect(parsed.groupOf('DR'), isNull);
      expect(parsed.groupOf('ZZ'), isNull);
    });
  });

  group('latestSnapshotPerRange', () {
    test('memilih snapshot dengan range_end terbaru per label', () {
      final rows = [
        row('ZP', BrokerSide.buy, 1, label: '1M', end: DateTime(2026, 10, 27)),
        row('ZP', BrokerSide.buy, 2, label: '1M', end: DateTime(2026, 10, 28)),
        row('ZP', BrokerSide.buy, 3, label: '3M', end: DateTime(2026, 10, 20)),
      ];

      final latest = latestSnapshotPerRange(rows);

      expect(latest.length, 2);
      expect(
        latest.firstWhere((r) => r.rangeLabel == '1M').valueIdr,
        2000000000,
      );
      expect(latest.any((r) => r.rangeLabel == '3M'), isTrue);
    });
  });

  test('BrokerRangeRow.fromMap membaca baris Supabase', () {
    final parsed = BrokerRangeRow.fromMap({
      'ticker': 'BBCA',
      'range_label': '1M',
      'range_start': '2026-09-28',
      'range_end': '2026-10-28',
      'broker_code': 'CC',
      'side': 'sell',
      'value_idr': 2200000000000,
      'value_is_approx': true,
    });

    expect(parsed.side, BrokerSide.sell);
    expect(parsed.signedValueIdr, -2200000000000);
    expect(parsed.isApprox, isTrue);
    expect(parsed.rangeEnd, DateTime(2026, 10, 28));
  });
}
