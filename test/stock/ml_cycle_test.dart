import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/stock/controllers/stock_detail_controller.dart';
import 'package:dompetku_app/features/stock/models/ml_cycle.dart';
import 'package:dompetku_app/features/stock/models/ml_prediction.dart';
import 'package:dompetku_app/features/stock/models/price_point.dart';
import 'package:dompetku_app/features/stock/widgets/ml_prediction_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'stock_fakes.dart';

/// Baris `ml_cycle` seperti dikirim PostgREST (angka numerik sebagai teks).
Map<String, dynamic> _row({
  String start = '2026-11-05',
  bool fiveDay = true,
  Map<String, dynamic> extra = const {},
}) => {
  'ticker': 'BBCA',
  'cycle_start': start,
  'close0': '4980',
  'model10': 'ml-logit-ta-tb10-2026-11-01',
  'prob10': '0.2728',
  'base10': '0.2722',
  'signal10': 'netral',
  'upper10': '0.1718',
  'lower10': '-0.1466',
  if (fiveDay) ...{
    'model5': 'ml-ta5-2026-11-06',
    'prob5': '0.31',
    'base5': '0.28',
    'signal5': 'peluang',
    'upper5': '0.12',
    'lower5': '-0.105',
  },
  ...extra,
};

/// Hari bursa berurutan, satu hari kalender tiap titik.
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
  group('MlCycle', () {
    test('membaca siklus lengkap dengan revisi dan hasil nyata', () {
      final c = MlCycle.tryFromMap(
        _row(
          extra: {
            'rev_date': '2026-11-12',
            'rev_state': 'diperbarui',
            'rev_prob': '0.41',
            'rev_base': '0.18',
            'out5_date': '2026-11-12',
            'out5_entry': '4990',
            'out5_exit': '5100',
            'out5_ret_net': '0.018',
            'out5_win': true,
            'out5_hit_upper': false,
            'out10_date': '2026-11-19',
            'out10_ret_net': '-0.02',
            'out10_win': false,
          },
        ),
      )!;
      expect(c.cycleStart, DateTime(2026, 11, 5));
      expect(c.tenDay.probUp, closeTo(0.2728, 1e-9));
      expect(c.fiveDay!.signal, MlSignal.peluang);
      expect(c.fiveDay!.outcome!.retNet, closeTo(0.018, 1e-9));
      expect(c.tenDay.outcome!.win, isFalse);
      expect(c.revision!.state, MlRevisionState.diperbarui);
      expect(c.revision!.probUp, closeTo(0.41, 1e-9));
      expect(c.isComplete, isTrue);
    });

    test('tanpa model 5 hari dan revisi, siklus tetap terbaca', () {
      final c = MlCycle.tryFromMap(_row(fiveDay: false))!;
      expect(c.fiveDay, isNull);
      expect(c.revision, isNull);
      expect(c.isComplete, isFalse);
    });

    test('baris tidak lengkap atau sinyal tidak dikenal menghasilkan null', () {
      expect(MlCycle.tryFromMap({..._row(), 'prob10': null}), isNull);
      expect(MlCycle.tryFromMap({..._row(), 'signal10': 'beli'}), isNull);
      expect(MlCycle.tryFromMap({..._row(), 'cycle_start': 'x'}), isNull);
    });

    test('revisi dengan batas tersentuh terbaca sebagai hasil pasti', () {
      final c = MlCycle.tryFromMap(
        _row(
          extra: {
            'rev_date': '2026-11-12',
            'rev_state': 'atas_tersentuh',
            'rev_prob': '1',
          },
        ),
      )!;
      expect(c.revision!.state, MlRevisionState.atasTersentuh);
      expect(c.revision!.baseRate, isNull);
    });

    test('toPrediction memuat prediksi 10 hari awal', () {
      final p = MlCycle.tryFromMap(_row())!.toPrediction();
      expect(p.tradeDate, DateTime(2026, 11, 5));
      expect(p.horizonDays, 10);
      expect(p.probUp, closeTo(0.2728, 1e-9));
      expect(p.closePrice, 4980);
    });
  });

  group('StockDetailController siklus', () {
    final start = DateTime(2026, 11, 5);

    test('prediksi yang dibaca mengikuti tanggal sinyal siklus', () async {
      final cycle = MlCycle.tryFromMap(_row())!;
      final daily = cycle.toPrediction();
      final newer = MlPrediction(
        ticker: 'BBCA',
        tradeDate: DateTime(2026, 11, 9),
        modelVersion: daily.modelVersion,
        horizonDays: 10,
        probUp: 0.5,
        baseRate: 0.27,
        signal: MlSignal.peluang,
        upperPct: 0.1,
        lowerPct: -0.1,
        drivers: const [],
      );
      final repo = FakeRepository()
        ..latestPrediction = newer
        ..cycles = {
          'BBCA': [cycle],
        }
        ..predictionsOn = [daily];
      final controller = StockDetailController(repo, 'BBCA');
      await controller.loadMl();
      // Prediksi harian terbaru (9/11) tidak menggeser jendela siklus (5/11).
      expect(controller.ml.value.data?.tradeDate, start);
      expect(controller.mlCycles, hasLength(1));
    });

    test('tanpa baris ml_prediction, kartu memakai prediksi siklus', () async {
      final repo = FakeRepository()
        ..cycles = {
          'BBCA': [MlCycle.tryFromMap(_row())!],
        };
      final controller = StockDetailController(repo, 'BBCA');
      await controller.loadMl();
      expect(controller.ml.value.data?.tradeDate, start);
      expect(controller.ml.value.data?.probUp, closeTo(0.2728, 1e-9));
    });

    test('siklus gagal dimuat: prediksi harian tetap dipakai', () async {
      final repo = FakeRepository()
        ..latestPrediction = MlCycle.tryFromMap(_row())!.toPrediction()
        ..failCycles = true;
      final controller = StockDetailController(repo, 'BBCA');
      await controller.loadMl();
      expect(controller.ml.value.data, isNotNull);
      expect(controller.mlCycles, isEmpty);
    });
  });

  group('kartu siklus', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(390, 5000);
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

    Widget card(List<MlCycle> cycles, {List<MlPrediction> past = const []}) =>
        MlPredictionCard(
          prediction: cycles.first.toPrediction(),
          pastPredictions: past,
          cycles: cycles,
          history: history,
        );

    testWidgets('siklus berjalan: hari ke-3, revisi belum tersedia', (
      tester,
    ) async {
      await pump(tester, card([MlCycle.tryFromMap(_row())!]));
      expect(find.text('SIKLUS 10 HARI BURSA'), findsOneWidget);
      expect(
        find.text('Sinyal 05/11/2026 · hari ke-3 dari 10'),
        findsOneWidget,
      );
      expect(find.text('MINGGU 1 · 5 HARI'), findsOneWidget);
      expect(find.text('Revisi tersedia setelah hari ke-5.'), findsOneWidget);
      // Tampilan harian tidak ikut: tanpa catatan "hasil nyata muncul".
      expect(
        find.textContaining('Hasil nyata muncul setelah prediksi genap'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa model 5 hari ada keterangannya', (tester) async {
      await pump(tester, card([MlCycle.tryFromMap(_row(fiveDay: false))!]));
      expect(
        find.text(
          'Model 5 hari belum aktif, jadi prediksi 5 hari tidak tampil.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('revisi diperbarui menampilkan skor revisi dan penjelasan', (
      tester,
    ) async {
      await pump(
        tester,
        card([
          MlCycle.tryFromMap(
            _row(
              extra: {
                'rev_date': '2026-11-12',
                'rev_state': 'diperbarui',
                'rev_prob': '0.41',
                'rev_base': '0.18',
              },
            ),
          )!,
        ]),
      );
      expect(find.text('skor 41 dari 100'), findsOneWidget);
      expect(
        find.textContaining('bukan dari model yang belajar'),
        findsOneWidget,
      );
    });

    testWidgets('batas tersentuh: hasil sudah ditentukan', (tester) async {
      await pump(
        tester,
        card([
          MlCycle.tryFromMap(
            _row(
              extra: {
                'rev_date': '2026-11-12',
                'rev_state': 'bawah_tersentuh',
                'rev_prob': '0',
              },
            ),
          )!,
        ]),
      );
      expect(
        find.textContaining('Batas bawah sudah tersentuh'),
        findsOneWidget,
      );
      expect(find.text('turun'), findsOneWidget);
    });

    testWidgets('riwayat siklus memuat siklus lama dengan hasilnya', (
      tester,
    ) async {
      final old = MlCycle.tryFromMap(
        _row(
          start: '2026-10-20',
          extra: {
            'rev_date': '2026-10-27',
            'rev_state': 'diperbarui',
            'rev_prob': '0.41',
            'out5_date': '2026-10-27',
            'out5_ret_net': '0.018',
            'out10_date': '2026-11-03',
            'out10_ret_net': '-0.02',
          },
        ),
      )!;
      await pump(
        tester,
        card(
          [MlCycle.tryFromMap(_row())!, old],
          // Riwayat harian tidak tampil bila ada siklus.
          past: [MlCycle.tryFromMap(_row(start: '2026-11-03'))!.toPrediction()],
        ),
      );
      expect(find.text('RIWAYAT SIKLUS'), findsOneWidget);
      expect(find.text('RIWAYAT PREDIKSI'), findsNothing);
      expect(find.text('20/10/2026'), findsOneWidget);
      expect(find.text('-2,0%'), findsOneWidget);
      expect(
        find.text('5 hari: +1,8% · 10 hari: skor 27 → revisi 41'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa siklus, tampilan harian tetap seperti semula', (
      tester,
    ) async {
      await pump(
        tester,
        MlPredictionCard(
          prediction: MlCycle.tryFromMap(_row())!.toPrediction(),
          history: history,
        ),
      );
      expect(find.text('SIKLUS 10 HARI BURSA'), findsNothing);
      expect(
        find.textContaining('Hasil nyata muncul setelah prediksi genap'),
        findsOneWidget,
      );
    });
  });
}
