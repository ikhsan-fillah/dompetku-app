import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/stock/controllers/stock_controller.dart';
import 'package:dompetku_app/features/stock/controllers/stock_detail_controller.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/models/watchlist_item.dart';
import 'package:dompetku_app/features/stock/pages/stock_detail_page.dart';
import 'package:dompetku_app/features/stock/pages/stock_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'stock_fakes.dart';

Future<void> pumpPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(Get.reset);
  await tester.pumpWidget(GetMaterialApp(theme: AppTheme.light, home: page));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('belum dikonfigurasi: menjelaskan --dart-define', (tester) async {
    Get.put(StockController(FakeAuth(configured: false), FakeRepository()));

    await pumpPage(tester, const StockPage());

    expect(find.text('Supabase belum dikonfigurasi'), findsOneWidget);
    expect(find.textContaining('--dart-define'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('masuk lalu tambah saham', (tester) async {
    final repository = FakeRepository();
    Get.put(StockController(FakeAuth(), repository));

    await pumpPage(tester, const StockPage());
    expect(find.text('Masuk ke Supabase'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'a@b.co');
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'rahasia',
    );
    await tester.tap(find.text('Masuk ke Supabase'));
    await tester.pumpAndSettle();

    expect(find.text('Watchlist masih kosong'), findsOneWidget);

    await tester.tap(find.byTooltip('Tambah saham'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Kode saham'),
      'bbca',
    );
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('BBCA'), findsOneWidget);
    expect(repository.items.single.ticker, 'BBCA');
    expect(tester.takeException(), isNull);
  });

  testWidgets('kode saham tidak valid menampilkan pesan di lembar tambah', (
    tester,
  ) async {
    Get.put(StockController(FakeAuth(hasSession: true), FakeRepository()));
    await pumpPage(tester, const StockPage());

    await tester.tap(find.byTooltip('Tambah saham'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Kode saham'), 'BB1');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Kode saham harus 4 huruf, contoh BBCA.'), findsOneWidget);
  });

  testWidgets('watchlist menampilkan saham dan status aktif', (tester) async {
    final repository = FakeRepository()
      ..items.addAll(const [
        WatchlistItem(ticker: 'BBCA', isActive: true),
        WatchlistItem(ticker: 'BBRI', isActive: false),
      ]);
    Get.put(StockController(FakeAuth(hasSession: true), repository));

    await pumpPage(tester, const StockPage());

    expect(find.text('BBCA'), findsOneWidget);
    expect(find.text('BBRI'), findsOneWidget);
    expect(find.text('aktif'), findsOneWidget);
    expect(find.text('nonaktif'), findsOneWidget);
  });

  testWidgets('detail: total kelompok dan baris per broker', (tester) async {
    final repository = FakeRepository()
      ..rows = [
        rangeRow('ZP', BrokerSide.buy, 536000000000, 'Latest'),
        rangeRow('YP', BrokerSide.sell, 149600000000, 'Latest'),
        rangeRow('CC', BrokerSide.sell, 2200000000000, '1M', approx: true),
      ];
    Get.put(StockDetailController(repository, 'BBCA'));

    await pumpPage(tester, const StockDetailPage());

    // Latest: ZP masuk Asing (+536 M); YP belum diklasifikasi.
    expect(find.text('+536,0 M'), findsWidgets);
    expect(find.text('ZP'), findsOneWidget);
    expect(find.text('YP'), findsOneWidget);
    expect(
      find.textContaining('Belum diklasifikasi: 1 broker'),
      findsOneWidget,
    );

    await tester.tap(find.text('1M'));
    await tester.pumpAndSettle();

    // Angka dibulatkan di layar sumber diberi awalan ≈.
    expect(find.text('≈-2,20 T'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
