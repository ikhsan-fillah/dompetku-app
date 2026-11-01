import 'dart:math' as math;

import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/stock/models/ml_prediction.dart';
import 'package:dompetku_app/features/stock/models/price_point.dart';
import 'package:dompetku_app/features/stock/widgets/ml_prediction_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Baris BBCA 30/10/2026 dari model ml-logit-ta-tb10-2026-11-01, seperti yang
/// dikirim PostgREST (angka numerik sebagai teks, model tersemat).
Map<String, dynamic> _row({
  Object? signal = 'netral',
  String ticker = 'BBCA',
  Map<String, dynamic> outcome = const {},
}) => {
  'ticker': ticker,
  'trade_date': '2026-10-30',
  'model_version': 'ml-logit-ta-tb10-2026-11-01',
  'horizon_days': 10,
  'prob_up': '0.2728',
  'base_rate': '0.2722',
  'signal': signal,
  'upper_pct': '0.1718',
  'lower_pct': '-0.1466',
  'close_price': '4980',
  'drivers': [
    {'value': -0.096, 'feature': 'distSma20', 'contribution': 0.553},
    {'value': 0.3636, 'feature': 'rsi', 'contribution': -0.333},
    {'value': -1.9154, 'feature': 'bbZ', 'contribution': 0.248},
    {'value': -0.1746, 'feature': 'distSma50', 'contribution': -0.235},
  ],
  ...outcome,
  'ml_model': {
    'trained_at': '2026-11-01T00:40:40.073323+00:00',
    'is_active': true,
    'universe': ['BBCA', 'BBRI'],
    'metrics': {
      'folds': [
        {'auc': 0.5602},
        {'auc': 0.5334},
        {'auc': 0.5129},
        {'auc': 0.5334},
        {'auc': 0.5516},
      ],
      'backtest': {
        'rule': 'beli harga buka besok, jual penutupan hari bursa ke-10',
        'nStocks': 44,
        'periods': 5,
        'testStart': '2023-12-05',
        'testEnd': '2026-10-16',
        'horizonDays': 10,
        'costRoundTrip': 0.004,
        'top10': {
          'winRate': 0.4767,
          'avgWin': 0.0689,
          'avgLoss': -0.0658,
          'netPerTrade': -0.0021,
          'trades': 3352,
        },
        'all': {
          'winRate': 0.4216,
          'avgWin': 0.0593,
          'avgLoss': -0.0582,
          'netPerTrade': -0.0087,
          'trades': 29749,
        },
      },
    },
  },
};

void main() {
  test('membaca baris lengkap dari teks numerik', () {
    final p = MlPrediction.tryFromMap(_row());
    expect(p, isNotNull);
    expect(p!.signal, MlSignal.netral);
    expect(p.probUp, closeTo(0.2728, 1e-9));
    expect(p.upperPct, closeTo(0.1718, 1e-9));
    expect(p.horizonDays, 10);
    expect(p.closePrice, 4980);
    expect(p.inUniverse, isTrue);
    expect(p.aucMean, closeTo(0.5383, 1e-4));
    expect(p.aucMin, closeTo(0.5129, 1e-9));
    expect(p.aucMax, closeTo(0.5602, 1e-9));
  });

  test('faktor terbesar diurutkan menurut besar sumbangan', () {
    final top = MlPrediction.tryFromMap(_row())!.topDrivers(3);
    expect(top.map((d) => d.feature), ['distSma20', 'rsi', 'bbZ']);
    expect(top[1].pushesUp, isFalse);
  });

  test('saham di luar data latih ditandai', () {
    final p = MlPrediction.tryFromMap(_row(ticker: 'CUAN'));
    expect(p!.inUniverse, isFalse);
  });

  test('sinyal tidak dikenal menghasilkan null', () {
    expect(MlPrediction.tryFromMap(_row(signal: 'beli')), isNull);
  });

  test('uji balik dibaca dari metrics model aktif', () {
    final b = MlPrediction.tryFromMap(_row())!.backtest;
    expect(b, isNotNull);
    expect(b!.top10.winRate, closeTo(0.4767, 1e-9));
    expect(b.all.trades, 29749);
    expect(b.top10.netPerTrade, isNegative);
    expect(b.testStart?.year, 2023);
    expect(b.costRoundTrip, closeTo(0.004, 1e-9));
  });

  test('hasil nyata kosong selama belum matang', () {
    expect(MlPrediction.tryFromMap(_row())!.outcome, isNull);
  });

  test('hasil nyata terbaca setelah matang', () {
    final p = MlPrediction.tryFromMap(
      _row(
        outcome: {
          'outcome_date': '2026-11-13',
          'outcome_entry': '4990',
          'outcome_exit': '5100',
          'outcome_ret_net': '0.018',
          'outcome_win': true,
          'outcome_hit_upper': false,
        },
      ),
    );
    final o = p!.outcome;
    expect(o, isNotNull);
    expect(o!.retNet, closeTo(0.018, 1e-9));
    expect(o.win, isTrue);
    expect(o.hitUpper, isFalse);
    expect(o.date, DateTime(2026, 11, 13));
  });

  group('kartu prediksi', () {
    final end = DateTime(2026, 10, 30);
    final history = [
      for (var i = 259; i >= 0; i--)
        PricePoint(
          ticker: 'BBCA',
          date: end.subtract(Duration(days: i)),
          close: 5000 + 400 * math.sin(i / 11),
          high: 5060 + 400 * math.sin(i / 11),
          low: 4940 + 400 * math.sin(i / 11),
        ),
    ];

    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(390, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tampil lengkap dengan riwayat dan hasil nyata', (
      tester,
    ) async {
      final matured = MlPrediction.tryFromMap(
        _row(
          outcome: {
            'outcome_date': '2026-11-13',
            'outcome_entry': '4990',
            'outcome_exit': '5100',
            'outcome_ret_net': '0.018',
            'outcome_win': true,
            'outcome_hit_upper': false,
          },
        ),
      );
      await pump(
        tester,
        MlPredictionCard(
          prediction: MlPrediction.tryFromMap(_row())!,
          matured: matured,
          history: history,
        ),
      );
      expect(find.textContaining('peluang naik'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saham di luar data latih, tanpa riwayat', (tester) async {
      await pump(
        tester,
        MlPredictionCard(
          prediction: MlPrediction.tryFromMap(_row(ticker: 'CUAN'))!,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
