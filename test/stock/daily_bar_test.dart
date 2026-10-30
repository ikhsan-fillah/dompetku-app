import 'package:dompetku_app/features/stock/models/broker_group.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/models/daily_bar.dart';
import 'package:dompetku_app/features/stock/services/broker_group_calculator.dart';
import 'package:dompetku_app/features/stock/services/technical_reading.dart';
import 'package:dompetku_app/features/stock/widgets/chart_painting.dart';
import 'package:dompetku_app/features/stock/widgets/group_flow_card.dart';
import 'package:dompetku_app/features/stock/widgets/stock_format.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stock_fakes.dart';

void main() {
  group('DailyBar.fromMap', () {
    test('angka bisa num atau teks, kolom kosong tetap null', () {
      final bar = DailyBar.fromMap({
        'ticker': 'BBCA',
        'trade_date': '2026-10-28',
        'close_price': 9150,
        'prev_close': 9100.0,
        'volume_lot': 52300000,
        'macd_hist': '-34.05',
        'stoch_rsi_a': 49.5,
        'open_price': null,
      });

      expect(bar.close, 9150);
      expect(bar.prevClose, 9100);
      expect(bar.macdHist, -34.05);
      expect(bar.stochA, 49.5);
      expect(bar.open, isNull);
      expect(bar.macdA, isNull);
      expect(bar.isIntraday, isFalse);
    });

    test('tanpa tanggal atau kode saham gagal keras', () {
      expect(
        () => DailyBar.fromMap({'ticker': 'BBCA', 'close_price': 9000}),
        throwsFormatException,
      );
      expect(
        () => DailyBar.fromMap({'trade_date': '2026-10-28'}),
        throwsFormatException,
      );
    });

    test('perubahan harga dan rasio volume dihitung dari kolomnya', () {
      final bar = dailyBar(
        1,
        close: 9100,
        prevClose: 9000,
        volumeLot: 3000000,
        volumeMa20: 6000000,
      );

      expect(bar.changePercent, closeTo(1.11, 0.01));
      expect(bar.volumeRatio, 0.5);
      expect(
        DailyBar(
          ticker: 'BBCA',
          tradeDate: DateTime(2026, 10, 28),
          close: 9100,
        ).changePercent,
        isNull,
      );
    });
  });

  test('oneBarPerDate: satu baris per tanggal, terlama dulu, dibatasi', () {
    final newestFirst = [
      dailyBar(3, close: 9300),
      dailyBar(3, close: 9999),
      dailyBar(2),
      dailyBar(1),
    ];

    final bars = oneBarPerDate(newestFirst, limit: 2);

    expect(bars.map((b) => b.close), [9000, 9300]);
  });

  test('latestBarPerTicker memilih tanggal terbaru tiap saham', () {
    final latest = latestBarPerTicker([
      dailyBar(1, ticker: 'BBCA'),
      dailyBar(5, ticker: 'BBCA', close: 9500),
      dailyBar(2, ticker: 'BBRI'),
    ]);

    expect(latest['BBCA']!.close, 9500);
    expect(latest['BBRI']!.tradeDate, DateTime(2026, 10, 3));
  });

  group('TechnicalReading', () {
    test('lineOrder: posisi garis pertama terhadap kedua', () {
      expect(TechnicalReading.lineOrder(56.9, 37.5), LineOrder.above);
      expect(TechnicalReading.lineOrder(-79, -77), LineOrder.below);
      expect(TechnicalReading.lineOrder(5, 5), LineOrder.equal);
      expect(TechnicalReading.lineOrder(null, 5), isNull);
    });

    test('histTrend: pekat bila membesar, pudar bila mengecil', () {
      // Negatif yang makin dalam tetap dihitung membesar.
      expect(TechnicalReading.histTrend(-4, -2), HistTrend.growing);
      expect(TechnicalReading.histTrend(-1.5, -2), HistTrend.shrinking);
      expect(TechnicalReading.histTrend(3, 3), HistTrend.growing);
      expect(TechnicalReading.histTrend(3, null), HistTrend.growing);
      expect(TechnicalReading.histTrend(null, 3), isNull);
    });

    test('Stoch RSI: batas 20 dan 80 termasuk area ujung', () {
      expect(TechnicalReading.stochZone(null), isNull);
      expect(TechnicalReading.stochZone(20), StochZone.oversold);
      expect(TechnicalReading.stochZone(20.1), StochZone.neutral);
      expect(TechnicalReading.stochZone(79.9), StochZone.neutral);
      expect(TechnicalReading.stochZone(80), StochZone.overbought);
    });

    test('MACD: posisi dua garis terhadap nol', () {
      MacdSide? side(double? a, double? b) =>
          TechnicalReading.macdSide(dailyBar(1, macdA: a, macdB: b));

      expect(side(-282.82, -316.87), MacdSide.bothBelow);
      expect(side(5, 3), MacdSide.bothAbove);
      expect(side(5, -3), MacdSide.mixed);
      expect(side(0, 3), MacdSide.mixed);
      expect(side(null, 3), isNull);
    });

    test('volume: batas rasio terhadap rata-rata 20 hari', () {
      expect(TechnicalReading.volumeLevel(null), isNull);
      expect(TechnicalReading.volumeLevel(1.5), VolumeLevel.farAbove);
      expect(TechnicalReading.volumeLevel(1), VolumeLevel.above);
      expect(TechnicalReading.volumeLevel(0.99), VolumeLevel.below);
      expect(TechnicalReading.volumeLevel(0.5), VolumeLevel.below);
      expect(TechnicalReading.volumeLevel(0.49), VolumeLevel.farBelow);
    });
  });

  group('format', () {
    test('harga memakai titik ribuan, volume ringkas dalam lot', () {
      expect(formatPrice(9150), '9.150');
      expect(formatPrice(950), '950');
      expect(formatPrice(1234567), '1.234.567');
      expect(formatLot(52300000), '52,3 jt');
      expect(formatLot(840000), '840,0 rb');
      expect(formatLot(120), '120');
    });

    test('persen dan indikator memakai koma desimal dan tanda', () {
      expect(formatPercent(1.24), '+1,2%');
      expect(formatPercent(-0.8), '-0,8%');
      expect(formatPercent(0), '0,0%');
      expect(formatIndicator(-282.82), '-282,82');
      expect(formatIndicator(49.56, digits: 1), '49,6');
      expect(formatDayMonth(DateTime(2026, 10, 8)), '08/10');
    });
  });

  group('flowHeadline', () {
    const rules = BrokerGroupRules({
      'XL': BrokerGroup.ritel,
      'AO': BrokerGroup.bandar,
      'ZP': BrokerGroup.asing,
    });
    String headline(List<BrokerRangeRow> rows) =>
        flowHeadline(const BrokerGroupCalculator().summarize(rows, rules));

    test('menyebut kelompok net beli dan net jual', () {
      expect(
        headline([
          rangeRow('ZP', BrokerSide.buy, 600, 'Latest'),
          rangeRow('XL', BrokerSide.sell, 300, 'Latest'),
          rangeRow('AO', BrokerSide.sell, 40, 'Latest'),
        ]),
        'Asing net beli, Ritel dan Bandar net jual.',
      );
    });

    test('hanya satu arah, atau tanpa arus bersih', () {
      expect(
        headline([
          rangeRow('XL', BrokerSide.buy, 1, 'Latest'),
          rangeRow('AO', BrokerSide.buy, 1, 'Latest'),
          rangeRow('ZP', BrokerSide.buy, 1, 'Latest'),
        ]),
        'Ritel, Bandar dan Asing net beli.',
      );
      expect(headline(const []), 'Tidak ada arus bersih pada rentang ini.');
      expect(
        headline([
          rangeRow('XL', BrokerSide.buy, 5, 'Latest'),
          rangeRow('XL', BrokerSide.sell, 5, 'Latest'),
        ]),
        'Tidak ada arus bersih pada rentang ini.',
      );
    });
  });

  test(
    'ChartFrame.indexAt memetakan sentuhan ke hari dan menjepit ujungnya',
    () {
      const width = 352.0 + ChartFrame.axisWidth;

      expect(ChartFrame.indexAt(0, width, 4), 0);
      expect(ChartFrame.indexAt(87, width, 4), 0);
      expect(ChartFrame.indexAt(89, width, 4), 1);
      expect(ChartFrame.indexAt(-30, width, 4), 0);
      expect(ChartFrame.indexAt(900, width, 4), 3);
      expect(ChartFrame.indexAt(10, width, 1), 0);

      final frame = ChartFrame(const Size(width, 100), 4);
      expect(frame.xOf(0), closeTo(44, 0.01));
      expect(frame.yOf(5, 0, 10), closeTo(frame.plot.center.dy, 0.01));
    },
  );
}
