import 'dart:math' as math;

import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/stock/controllers/stock_detail_controller.dart';
import 'package:dompetku_app/features/stock/models/price_point.dart';
import 'package:dompetku_app/features/stock/pages/stock_detail_page.dart';
import 'package:dompetku_app/features/stock/services/risk_analysis.dart';
import 'package:dompetku_app/features/stock/services/risk_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stock_fakes.dart';

/// [n] hari berurutan dengan penutupan [close]; [lows] menimpa harga terendah
/// hari tertentu. Tanggal bergeser satu hari kalender per bar.
List<PricePoint> flat(
  int n, {
  double close = 100,
  Map<int, double> lows = const {},
  double Function(int i)? closeAt,
}) => [
  for (var i = 0; i < n; i++)
    PricePoint(
      ticker: 'BBCA',
      date: DateTime(2025, 1, 1).add(Duration(days: i)),
      close: closeAt?.call(i) ?? close,
      open: closeAt?.call(i) ?? close,
      high: (closeAt?.call(i) ?? close) * 1.001,
      low: lows[i] ?? (closeAt?.call(i) ?? close),
      volume: 1000000,
    ),
];

void main() {
  group('RiskAnalysis', () {
    test('riwayat kurang dari 80 hari: tidak dihitung', () {
      expect(RiskAnalysis.from(flat(79)), isNull);
    });

    test('frekuensi sentuh: jendela yang memuat harga terendah dihitung', () {
      // Harga terendah 94 di hari ke-50: jendela hari acuan 40 sampai 49
      // memuatnya, dari 90 jendela. Penurunan 6% tepat menyentuh CL 6%.
      final a = RiskAnalysis.from(flat(100, lows: {50: 94}))!;
      expect(a.windows, 90);
      expect(a.rateAt(5).all, closeTo(10 / 90, 1e-9));
      expect(a.rateAt(6).all, closeTo(10 / 90, 1e-9));
      expect(a.rateAt(7).all, 0);
      expect(a.rateAt(2).recent, isNull, reason: 'riwayat pendek');
    });

    test('pembanding setahun hanya memuat 250 jendela terakhir', () {
      final a = RiskAnalysis.from(flat(400, lows: {380: 94}))!;
      expect(a.rateAt(5).all, closeTo(10 / 390, 1e-9));
      expect(a.rateAt(5).recent, closeTo(10 / 250, 1e-9));
      // Lonjakan lama di luar 250 jendela terakhir tidak ikut.
      final old = RiskAnalysis.from(flat(400, lows: {60: 94}))!;
      expect(old.rateAt(5).all, closeTo(10 / 390, 1e-9));
      expect(old.rateAt(5).recent, 0);
    });

    test(
      'gerak harian: 20 hari terakhir jauh di atas biasanya = sangat liar',
      () {
        var price = 1000.0;
        final closes = <double>[];
        for (var i = 0; i < 320; i++) {
          final step = i < 295 ? 0.01 : 0.03;
          price *= math.exp(i.isEven ? step : -step);
          closes.add(price);
        }
        final a = RiskAnalysis.from(flat(320, closeAt: (i) => closes[i]))!;
        expect(a.moveTypical, closeTo(1.0, 0.15));
        expect(a.moveNow, closeTo(3.1, 0.2));
        expect(a.ratio, greaterThan(2.5));
        expect(a.state, VolatilityState.veryWild);
      },
    );

    test('gerak sama dengan biasanya = biasa', () {
      var price = 1000.0;
      final closes = [
        for (var i = 0; i < 320; i++)
          price *= math.exp(i.isEven ? 0.01 : -0.01),
      ];
      final a = RiskAnalysis.from(flat(320, closeAt: (i) => closes[i]))!;
      expect(a.state, VolatilityState.usual);
    });
  });

  group('positionSize', () {
    test('contoh desain: modal 50 jt, risiko 1%, CL 5%, harga 5.200', () {
      final s = positionSize(
        capital: 50000000,
        riskPercent: 1,
        cutLossPercent: 5,
        price: 5200,
      )!;
      expect(s.lots, 19);
      expect(s.cost, 9880000);
      expect(s.stopPrice, closeTo(4940, 1e-9));
      expect(s.loss, closeTo(494000, 1e-6));
      expect(s.limitedByCapital, isFalse);
    });

    test('CL lebih ketat memberi lot lebih banyak', () {
      final tight = positionSize(
        capital: 50000000,
        riskPercent: 1,
        cutLossPercent: 3,
        price: 5200,
      )!;
      expect(tight.lots, 32);
    });

    test('dibatasi modal bila risiko mengizinkan lot lebih banyak', () {
      final s = positionSize(
        capital: 5000000,
        riskPercent: 10,
        cutLossPercent: 2,
        price: 5200,
      )!;
      expect(s.lots, 9);
      expect(s.limitedByCapital, isTrue);
      expect(s.loss, lessThan(500000));
    });

    test('satu lot pun tidak muat atau masukan tidak valid: null', () {
      expect(
        positionSize(
          capital: 100000,
          riskPercent: 1,
          cutLossPercent: 5,
          price: 5200,
        ),
        isNull,
      );
      expect(
        positionSize(
          capital: 50000000,
          riskPercent: 0,
          cutLossPercent: 5,
          price: 5200,
        ),
        isNull,
      );
    });
  });

  group('tab Risiko', () {
    Future<void> pump(WidgetTester tester, StockDetailController c) async {
      tester.view.physicalSize = const Size(390, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(Get.reset);
      Get.put(c);
      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.light, home: const StockDetailPage()),
      );
      await tester.pumpAndSettle();
    }

    List<PricePoint> series() => flat(
      300,
      closeAt: (i) => i == 299 ? 5200 : 5000 + 120 * math.sin(i / 7),
      lows: {250: 4700},
    );

    testWidgets('dimuat saat dibuka: gerak, frekuensi CL, ukuran posisi', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repository = FakeRepository()..history = {'BBCA': series()};
      await pump(tester, StockDetailController(repository, 'BBCA'));

      await tester.tap(find.text('Risiko'));
      await tester.pumpAndSettle();

      expect(find.text('GERAK HARIAN TERUKUR'), findsOneWidget);
      expect(find.text('SEBERAPA SERING CL-MU KENA'), findsOneWidget);
      expect(
        find.textContaining('batasmu', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('HITUNG UKURAN POSISI'), findsOneWidget);
      expect(find.text('contoh angka'), findsOneWidget);
      expect(find.textContaining('19'), findsWidgets);
      expect(find.text('SEBERAPA BISA DIPERCAYA'), findsOneWidget);
      expect(
        find.textContaining('bukan rekomendasi beli atau jual'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ubah isian: lot dihitung ulang dan tersimpan', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = FakeRepository()..history = {'BBCA': series()};
      final controller = StockDetailController(repository, 'BBCA');
      await pump(tester, controller);
      await tester.tap(find.text('Risiko'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rugi maksimal'));
      await tester.pumpAndSettle();
      expect(find.text('Ukuran posisi'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'CL (% turun dari harga beli)'),
        '3',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(controller.riskInputs.value.cutLossPercent, 3);
      expect(controller.riskInputs.value.isExample, isFalse);
      expect(find.text('contoh angka'), findsNothing);
      final saved = await const RiskPrefs().load();
      expect(saved.cutLossPercent, 3);
      expect(saved.isExample, isFalse);
    });

    testWidgets('isian tidak valid: pesan galat, dialog tetap terbuka', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repository = FakeRepository()..history = {'BBCA': series()};
      await pump(tester, StockDetailController(repository, 'BBCA'));
      await tester.tap(find.text('Risiko'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rugi maksimal'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Modal (Rp)'),
        '500',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Modal minimal Rp 1.000.000.'), findsOneWidget);
      expect(find.text('Ukuran posisi'), findsOneWidget);
    });

    testWidgets('riwayat terlalu pendek: penjelasan, bukan kartu kosong', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repository = FakeRepository()..history = {'BBCA': flat(40)};
      await pump(tester, StockDetailController(repository, 'BBCA'));

      await tester.tap(find.text('Risiko'));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat harga belum cukup'), findsOneWidget);
      expect(find.text('GERAK HARIAN TERUKUR'), findsNothing);
    });
  });
}
