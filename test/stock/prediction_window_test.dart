import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/stock/controllers/stock_detail_controller.dart';
import 'package:dompetku_app/features/stock/models/ml_prediction.dart';
import 'package:dompetku_app/features/stock/models/price_point.dart';
import 'package:dompetku_app/features/stock/services/prediction_window.dart';
import 'package:dompetku_app/features/stock/widgets/ml_prediction_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'stock_fakes.dart';

MlPrediction _prediction(DateTime day, {MlOutcome? outcome}) => MlPrediction(
  ticker: 'BBCA',
  tradeDate: day,
  modelVersion: 'ml-logit-ta-tb10-2026-11-01',
  horizonDays: 10,
  probUp: 0.27,
  baseRate: 0.27,
  signal: MlSignal.netral,
  upperPct: 0.17,
  lowerPct: -0.14,
  drivers: const [],
  closePrice: 5000,
  outcome: outcome,
);

/// Hari bursa berurutan mulai [start], satu hari kalender tiap titik.
List<PricePoint> _bars(DateTime start, int count) => [
  for (var i = 0; i < count; i++)
    PricePoint(
      ticker: 'BBCA',
      date: start.add(Duration(days: i)),
      close: 5000 + i.toDouble(),
      high: 5010 + i.toDouble(),
      low: 4990 + i.toDouble(),
    ),
];

void main() {
  group('PredictionWindow', () {
    final signal = DateTime(2026, 11, 5);

    test('jendela dimulai dari tanggal sinyal dan tidak ikut hari ini', () {
      // 30 hari sampai 5/11 (hari sinyal), lalu 3 hari sesudahnya.
      final history = _bars(DateTime(2026, 10, 7), 30 + 3);
      final w = PredictionWindow.of(_prediction(signal), history);
      expect(w.signalDate, signal);
      expect(w.elapsed, 3);
      expect(w.remaining, 7);
      expect(w.isComplete, isFalse);
      expect(w.endDate, isNull);
      expect(w.realized.first.date, DateTime(2026, 11, 6));
    });

    test('belum ada hari sesudah sinyal', () {
      final history = _bars(DateTime(2026, 10, 7), 30);
      final w = PredictionWindow.of(_prediction(signal), history);
      expect(w.elapsed, 0);
      expect(w.endDate, isNull);
    });

    test('jendela genap berhenti di hari ke-10, walau data lebih panjang', () {
      final history = _bars(DateTime(2026, 10, 7), 30 + 15);
      final w = PredictionWindow.of(_prediction(signal), history);
      expect(w.isComplete, isTrue);
      expect(w.elapsed, 10);
      expect(w.endDate, DateTime(2026, 11, 15));
    });

    test('prediksi lama tetap di jendelanya saat data terus bertambah', () {
      final history = _bars(DateTime(2026, 10, 7), 30 + 15);
      final old = PredictionWindow.of(
        _prediction(DateTime(2026, 10, 20)),
        history,
      );
      final next = PredictionWindow.of(
        _prediction(DateTime(2026, 10, 21)),
        history,
      );
      expect(old.endDate, DateTime(2026, 10, 30));
      expect(next.endDate, DateTime(2026, 10, 31));
    });

    test('riwayat kosong menghasilkan jendela belum jalan', () {
      final w = PredictionWindow.of(_prediction(signal), const []);
      expect(w.elapsed, 0);
      expect(w.isComplete, isFalse);
    });

    test('historyUpTo memotong hari sesudah tanggal sinyal', () {
      final history = _bars(DateTime(2026, 10, 7), 33);
      final cut = historyUpTo(history, signal);
      expect(cut.last.date, signal);
      expect(cut.length, 30);
    });
  });

  group('StockDetailController riwayat prediksi', () {
    test('loadMl memuat riwayat terbaru dulu', () async {
      final repo = FakeRepository()
        ..latestPrediction = _prediction(DateTime(2026, 11, 5))
        ..predictionHistory = {
          'BBCA': [
            _prediction(DateTime(2026, 11, 5)),
            _prediction(DateTime(2026, 11, 4)),
            _prediction(DateTime(2026, 11, 3)),
          ],
        };
      final controller = StockDetailController(repo, 'BBCA');
      await controller.loadMl();
      expect(controller.ml.value.data?.tradeDate, DateTime(2026, 11, 5));
      expect(controller.mlHistory.map((p) => p.tradeDate), [
        DateTime(2026, 11, 5),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 3),
      ]);
    });

    test('riwayat gagal dimuat tidak merusak prediksi terbaru', () async {
      final repo = FakeRepository()
        ..latestPrediction = _prediction(DateTime(2026, 11, 5))
        ..failPredictionHistory = true;
      final controller = StockDetailController(repo, 'BBCA');
      await controller.loadMl();
      expect(controller.ml.value.data, isNotNull);
      expect(controller.mlHistory, isEmpty);
    });
  });

  group('kartu prediksi dengan jendela tetap', () {
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

    // Sinyal 5/11, tiga hari sudah berjalan sesudahnya.
    final history = _bars(DateTime(2026, 10, 7), 33);

    testWidgets('sinyal lama menampilkan jendelanya sendiri, bukan hari ini', (
      tester,
    ) async {
      await pump(
        tester,
        MlPredictionCard(
          prediction: _prediction(DateTime(2026, 11, 5)),
          history: history,
        ),
      );
      expect(
        find.textContaining('hari ke-3 dari 10 hari bursa'),
        findsOneWidget,
      );
      expect(find.textContaining('05/11/2026'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('jendela genap menampilkan tanggal selesai', (tester) async {
      await pump(
        tester,
        MlPredictionCard(
          prediction: _prediction(DateTime(2026, 10, 20)),
          history: history,
        ),
      );
      expect(find.textContaining('selesai pada 30/10/2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('riwayat memuat prediksi lama dengan status masing-masing', (
      tester,
    ) async {
      final matured = _prediction(
        DateTime(2026, 10, 20),
        outcome: MlOutcome(date: DateTime(2026, 10, 30), retNet: 0.018),
      );
      await pump(
        tester,
        MlPredictionCard(
          prediction: _prediction(DateTime(2026, 11, 5)),
          pastPredictions: [
            _prediction(DateTime(2026, 11, 5)),
            _prediction(DateTime(2026, 11, 3)),
            matured,
          ],
          history: history,
        ),
      );
      expect(find.text('RIWAYAT PREDIKSI'), findsOneWidget);
      // Prediksi yang sedang dibaca tidak diulang di daftar.
      expect(find.text('05/11/2026'), findsNothing);
      expect(find.text('03/11/2026'), findsOneWidget);
      expect(find.text('hari ke-5/10'), findsOneWidget);
      expect(find.text('20/10/2026'), findsOneWidget);
      expect(find.text('+1,8%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa prediksi lain, kartu riwayat tidak tampil', (
      tester,
    ) async {
      await pump(
        tester,
        MlPredictionCard(
          prediction: _prediction(DateTime(2026, 11, 5)),
          pastPredictions: [_prediction(DateTime(2026, 11, 5))],
          history: history,
        ),
      );
      expect(find.text('RIWAYAT PREDIKSI'), findsNothing);
    });
  });
}
