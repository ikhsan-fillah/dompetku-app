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
  'AK': BrokerGroup.bandar,
  'BK': BrokerGroup.bandar,
  'CC': BrokerGroup.bandar,
  'DX': BrokerGroup.bandar,
  'TP': BrokerGroup.bandar,
});

void main() {
  const calculator = BrokerGroupCalculator();

  test('Ritel dijumlahkan semua, Asing dari foreign, Bandar dari label', () {
    final summary = calculator.summarize(
      [
        row('XL', BrokerSide.sell, 189.3),
        row('XC', BrokerSide.sell, 59.5),
        row('PD', BrokerSide.sell, 53.1),
        row('IF', BrokerSide.buy, 82.4),
        row('SQ', BrokerSide.sell, 120),
      ],
      rules,
      foreignRows: [
        row('ZP', BrokerSide.buy, 536),
        row('CC', BrokerSide.sell, 468.3),
      ],
    );

    expect(summary.of(BrokerGroup.ritel).netIdr, -301900000000);
    expect(summary.of(BrokerGroup.ritel).sellIdr, 301900000000);
    expect(summary.of(BrokerGroup.ritel).buyIdr, 0);
    expect(summary.of(BrokerGroup.bandar).netIdr, -37600000000);
    expect(summary.of(BrokerGroup.asing).netIdr, 67700000000);
    expect(summary.of(BrokerGroup.ritel).brokerCount, 3);
    expect(summary.of(BrokerGroup.asing).brokerCount, 2);
  });

  test('Bandar hanya dari top 5 di sisinya, sisanya tidak dihitung', () {
    // Sisi beli: 6 broker. Peringkat dari nilai semua broker di sisi itu,
    // jadi XL (ritel) di peringkat 1 menggeser satu broker bandar keluar.
    final summary = calculator.summarize([
      row('XL', BrokerSide.buy, 100),
      row('IF', BrokerSide.buy, 90),
      row('SQ', BrokerSide.buy, 80),
      row('AK', BrokerSide.buy, 70),
      row('BK', BrokerSide.buy, 60),
      row('CC', BrokerSide.buy, 50),
      row('DX', BrokerSide.buy, 40),
    ], rules);

    // Top 5 = XL, IF, SQ, AK, BK. CC dan DX bandar di peringkat 6 dan 7.
    expect(summary.of(BrokerGroup.bandar).brokerCount, 4);
    expect(summary.of(BrokerGroup.bandar).buyIdr, 300000000000);
    expect(summary.of(BrokerGroup.ritel).buyIdr, 100000000000);
    // Bandar di luar top 5 bukan "belum diklasifikasi".
    expect(summary.unclassified.brokerCount, 0);
  });

  test('top 5 dihitung per sisi dan per rentang', () {
    final rows = [
      for (final label in ['Latest', '1M'])
        for (final code in ['IF', 'SQ', 'AK', 'BK', 'CC', 'DX'])
          row(code, BrokerSide.buy, 10, label: label),
    ];
    // Satu rentang: 6 bandar, hanya 5 dihitung. Dua rentang: 5 + 5 baris.
    expect(
      calculator
          .summarize(rows.where((r) => r.rangeLabel == 'Latest'), rules)
          .of(BrokerGroup.bandar)
          .brokerCount,
      5,
    );
    expect(
      calculator.summarize(rows, rules).of(BrokerGroup.bandar).brokerCount,
      10,
    );
  });

  test('Asing hanya top 10 per sisi dan rentang, peringkat dari nilai', () {
    final foreign = [
      for (var i = 1; i <= 12; i++) row('F$i', BrokerSide.buy, i.toDouble()),
      row('F1', BrokerSide.sell, 5),
      for (var i = 1; i <= 11; i++)
        row('G$i', BrokerSide.buy, i.toDouble(), label: '7D'),
    ];
    final latest = calculator
        .summarize(
          const [],
          rules,
          foreignRows: foreign.where((r) => r.rangeLabel == 'Latest'),
        )
        .of(BrokerGroup.asing);
    // 12 baris beli: nilai 3..12 yang masuk (10 teratas), jumlah 75 miliar.
    expect(latest.buyIdr, 75000000000);
    expect(latest.sellIdr, 5000000000);
    expect(latest.brokerCount, 11);

    final both = calculator
        .summarize(const [], rules, foreignRows: foreign)
        .of(BrokerGroup.asing);
    // 7D punya 11 baris beli: nilai 2..11 masuk, jumlah 65 miliar.
    expect(both.buyIdr, 75000000000 + 65000000000);
  });

  test('Ritel hanya yang masuk top 10 di sisinya', () {
    final rows = [
      for (var i = 1; i <= 10; i++) row('Z$i', BrokerSide.buy, 100.0 + i),
      row('XL', BrokerSide.buy, 1),
      row('XC', BrokerSide.buy, 500),
    ];
    final ritel = calculator.summarize(rows, rules).of(BrokerGroup.ritel);
    // XC masuk top 10 (500), XL (1) peringkat 12 sehingga tidak dihitung.
    expect(ritel.buyIdr, 500000000000);
    expect(ritel.brokerCount, 1);
  });

  test('label asing di broker_group tidak dihitung sebagai Asing', () {
    final summary = calculator.summarize([
      row('ZP', BrokerSide.buy, 10),
    ], const BrokerGroupRules({'ZP': BrokerGroup.asing}));

    expect(summary.of(BrokerGroup.asing).brokerCount, 0);
    expect(summary.unclassified.brokerCount, 1);
  });

  test('broker di luar aturan masuk belum diklasifikasi, bukan kelompok', () {
    final summary = calculator.summarize([
      row('YP', BrokerSide.sell, 149.6),
    ], rules);

    expect(summary.unclassified.netIdr, -149600000000);
    expect(summary.unclassified.brokerCount, 1);
    expect(summary.of(BrokerGroup.ritel).brokerCount, 0);
  });

  test('nilai yang dibulatkan di layar sumber ditandai di kelompoknya', () {
    final summary = calculator.summarize(
      [row('CC', BrokerSide.sell, 2200, approx: true)],
      rules,
      foreignRows: [row('ZP', BrokerSide.buy, 221.5, approx: true)],
    );

    expect(summary.of(BrokerGroup.bandar).hasApprox, isTrue);
    expect(summary.of(BrokerGroup.asing).approxCount, 1);
    expect(summary.of(BrokerGroup.ritel).hasApprox, isFalse);
  });

  test('tanpa baris, semua kelompok nol', () {
    final summary = calculator.summarize(const [], rules);

    for (final group in BrokerGroup.values) {
      expect(summary.of(group).netIdr, 0);
      expect(summary.of(group).brokerCount, 0);
    }
    expect(summary.unclassified.brokerCount, 0);
  });

  test('foreign hanya dipakai bila tanggalnya sama dengan data broker', () {
    final broker = [row('XL', BrokerSide.buy, 1, end: DateTime(2026, 11, 13))];
    final foreign = [
      row('ZP', BrokerSide.buy, 1, end: DateTime(2026, 11, 13)),
      row('KZ', BrokerSide.buy, 1, end: DateTime(2026, 11, 12)),
      row('AK', BrokerSide.buy, 1, end: DateTime(2026, 11, 13), label: '1M'),
    ];

    final kept = foreignMatchingBroker(broker, foreign);

    expect([for (final r in kept) r.brokerCode], ['ZP']);
  });

  group('BrokerGroupRules', () {
    test('membaca baris broker_group dan melewati kelompok tak dikenal', () {
      final parsed = BrokerGroupRules.fromRows([
        {'broker_code': 'xl', 'grp': 'ritel'},
        {'broker_code': 'AZ', 'grp': 'bandar'},
        {'broker_code': 'ZP', 'grp': 'asing'},
        {'broker_code': 'DX', 'grp': 'big_player'},
        {'broker_code': 'DR', 'grp': 'belum_diklasifikasi'},
        {'broker_code': 'ZZ', 'grp': 'baik'},
      ]);

      expect(parsed.groupOf('XL'), BrokerGroup.ritel);
      expect(parsed.groupOf('AZ'), BrokerGroup.bandar);
      expect(parsed.groupOf('ZP'), isNull);
      expect(parsed.groupOf('DX'), BrokerGroup.bandar);
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
