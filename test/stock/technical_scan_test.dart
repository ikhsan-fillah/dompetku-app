import 'package:dompetku_app/features/stock/models/price_point.dart';
import 'package:dompetku_app/features/stock/services/technical_scan.dart';
import 'package:flutter_test/flutter_test.dart';

PricePoint _bar(
  int i,
  double close, {
  double? open,
  double? high,
  double? low,
}) => PricePoint(
  ticker: 'TEST',
  date: DateTime(2026, 1, 1).add(Duration(days: i)),
  close: close,
  open: open,
  high: high,
  low: low,
  volume: 1000,
);

void main() {
  test('hammer dikenali pada bar terakhir dalam penurunan', () {
    final history = [
      for (var i = 0; i < 29; i++)
        _bar(
          i,
          1000 - 5.0 * i,
          open: 1010 - 5.0 * i,
          high: 1015 - 5.0 * i,
          low: 985 - 5.0 * i,
        ),
      _bar(29, 865, open: 860, high: 866, low: 800),
    ];
    expect(TechnicalScan(history).candles(), [CandlePattern.hammer]);
  });

  test('tidak ada pola candlestick bila data kurang', () {
    final history = [for (var i = 0; i < 10; i++) _bar(i, 1000)];
    expect(TechnicalScan(history).candles(), isEmpty);
  });

  test('double bottom sama dengan detektor lab (breakout bar 94)', () {
    // Seri yang sama dengan uji silang di kode lab patterns.ts: datar 1000,
    // turun ke 800, naik ke 900, turun ke 805, lalu naik ke 960. Kode lab
    // memberi P-DBOT di t = 94 dengan titik kunci 59, 71, 83.
    final closes = <double>[for (var k = 0; k < 40; k++) 1000];
    void seg(double from, double to, int n) {
      for (var k = 1; k <= n; k++) {
        closes.add(from + (to - from) * k / n);
      }
    }

    seg(1000, 800, 20);
    seg(800, 900, 12);
    seg(900, 805, 12);
    seg(805, 960, 16);
    final history = [
      for (var i = 0; i < closes.length; i++)
        _bar(i, closes[i], high: closes[i] * 1.005, low: closes[i] * 0.995),
    ];
    final event = TechnicalScan(history).latestChartPattern();
    expect(event, isNotNull);
    expect(event!.kind, ChartPatternKind.doubleBottom);
    expect(event.breakout, history[94].date);
    expect(event.keyDates, [
      history[59].date,
      history[71].date,
      history[83].date,
    ]);
    expect(TechnicalScan(history.sublist(0, 92)).latestChartPattern(), isNull);
  });

  test('skenario E5, B4, A4 dihitung dengan jumlah syarat 3, 4, 4', () {
    final history = [
      for (var i = 0; i < 260; i++)
        _bar(
          i,
          1000 + 50 * (i % 7 - 3).toDouble(),
          high: 1000 + 50 * (i % 7 - 3) + 10,
          low: 1000 + 50 * (i % 7 - 3) - 10,
        ),
    ];
    final checks = TechnicalScan(history).scenarios();
    expect([for (final c in checks) c.code], ['E5', 'B4', 'A4']);
    expect([for (final c in checks) c.total], [3, 4, 4]);
  });
}
