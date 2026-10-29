import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/stock/controllers/stock_controller.dart';
import 'package:dompetku_app/features/stock/controllers/stock_detail_controller.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/models/watchlist_item.dart';
import 'package:dompetku_app/features/stock/pages/stock_detail_page.dart';
import 'package:dompetku_app/features/stock/pages/stock_page.dart';
import 'package:dompetku_app/features/stock/widgets/stock_login_dialog.dart';
import 'package:dompetku_app/features/stock/widgets/technical_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'stock_fakes.dart';

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  double height = 1600,
}) async {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(Get.reset);
  await tester.pumpWidget(GetMaterialApp(theme: AppTheme.light, home: page));
  await tester.pumpAndSettle();
}

Future<void> fillLogin(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
  await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
}

void main() {
  group('masuk lewat dialog', () {
    testWidgets('belum dikonfigurasi: menjelaskan --dart-define', (
      tester,
    ) async {
      Get.put(StockController(FakeAuth(configured: false), FakeRepository()));

      await pumpPage(tester, const StockPage());

      expect(find.text('Supabase belum dikonfigurasi'), findsOneWidget);
      expect(find.textContaining('--dart-define'), findsOneWidget);
      expect(find.byType(StockLoginDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa sesi: dialog masuk muncul sendiri, lalu watchlist', (
      tester,
    ) async {
      final repository = FakeRepository();
      Get.put(StockController(FakeAuth(), repository));

      await pumpPage(tester, const StockPage());

      expect(find.byType(StockLoginDialog), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

      await fillLogin(tester, 'a@b.co', 'rahasia');
      await tester.tap(find.text('Masuk akun'));
      await tester.pumpAndSettle();

      expect(find.byType(StockLoginDialog), findsNothing);
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

    testWidgets('password salah: pesan tampil dan dialog tetap terbuka', (
      tester,
    ) async {
      Get.put(
        StockController(
          FakeAuth()..signInError = 'Invalid login credentials',
          FakeRepository(),
        ),
      );
      await pumpPage(tester, const StockPage());

      await fillLogin(tester, 'a@b.co', 'salah');
      await tester.tap(find.text('Masuk akun'));
      await tester.pumpAndSettle();

      expect(find.byType(StockLoginDialog), findsOneWidget);
      expect(find.text('Invalid login credentials'), findsOneWidget);
    });

    testWidgets('batal: halaman terkunci dan tombolnya membuka dialog lagi', (
      tester,
    ) async {
      Get.put(StockController(FakeAuth(), FakeRepository()));
      await pumpPage(tester, const StockPage());

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.byType(StockLoginDialog), findsNothing);
      expect(find.text('Watchlist terkunci'), findsOneWidget);

      await tester.tap(find.text('Masuk ke Supabase'));
      await tester.pumpAndSettle();

      expect(find.byType(StockLoginDialog), findsOneWidget);
    });

    testWidgets('email dan password kosong: pesan, tanpa memanggil Supabase', (
      tester,
    ) async {
      Get.put(StockController(FakeAuth(), FakeRepository()));
      await pumpPage(tester, const StockPage());

      await tester.tap(find.text('Masuk akun'));
      await tester.pumpAndSettle();

      expect(find.text('Email dan password wajib diisi.'), findsOneWidget);
    });

    testWidgets('password bisa ditampilkan dan disembunyikan', (tester) async {
      Get.put(StockController(FakeAuth(), FakeRepository()));
      await pumpPage(tester, const StockPage());

      TextField password() =>
          tester.widget(find.widgetWithText(TextField, 'Password'));
      expect(password().obscureText, isTrue);

      await tester.tap(find.byTooltip('Tampilkan password'));
      await tester.pumpAndSettle();

      expect(password().obscureText, isFalse);
    });

    testWidgets('keluar dari halaman tidak memunculkan dialog lagi', (
      tester,
    ) async {
      final repository = FakeRepository()
        ..items.add(const WatchlistItem(ticker: 'BBCA', isActive: true));
      Get.put(StockController(FakeAuth(hasSession: true), repository));
      await pumpPage(tester, const StockPage());

      await tester.scrollUntilVisible(
        find.text('Keluar dari Supabase'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Keluar dari Supabase'));
      await tester.pumpAndSettle();

      expect(find.text('Watchlist terkunci'), findsOneWidget);
      expect(find.byType(StockLoginDialog), findsNothing);
    });

    testWidgets(
      'dialog bisa dibuka langsung dan hasilnya false bila dibatalkan',
      (tester) async {
        final controller = StockController(FakeAuth(), FakeRepository());
        Get.put(controller);
        bool? result;
        await pumpPage(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await showStockLoginDialog(context, controller),
                child: const Text('buka'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('buka'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(result, isFalse);
      },
    );
  });

  group('watchlist', () {
    testWidgets('kartu: status, harga, arah dana kelompok, dan tanggal data', (
      tester,
    ) async {
      final repository = FakeRepository()
        ..items.addAll(const [
          WatchlistItem(ticker: 'BBCA', isActive: true),
          WatchlistItem(ticker: 'BBRI', isActive: false),
        ])
        ..rows = [
          rangeRow('ZP', BrokerSide.buy, 621800000000, 'Latest'),
          rangeRow('XL', BrokerSide.sell, 301900000000, 'Latest'),
        ]
        ..bars = [
          dailyBar(1, close: 9000),
          dailyBar(2, close: 9100, prevClose: 9000),
        ];
      Get.put(StockController(FakeAuth(hasSession: true), repository));

      await pumpPage(tester, const StockPage());

      expect(find.text('BBCA'), findsOneWidget);
      expect(find.text('BBRI'), findsOneWidget);
      expect(find.text('aktif'), findsOneWidget);
      expect(find.text('nonaktif'), findsOneWidget);
      expect(find.text('Rp 9.100'), findsOneWidget);
      expect(find.text('+1,1%'), findsOneWidget);
      expect(find.text('+621,8 M'), findsOneWidget);
      expect(find.text('-301,9 M'), findsOneWidget);
      expect(find.text('Data broker 28/10/2026 (Latest)'), findsOneWidget);
      // BBRI belum punya data broker.
      expect(find.text('Belum ada data broker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('penyaring menyembunyikan saham yang tidak dipilih', (
      tester,
    ) async {
      final repository = FakeRepository()
        ..items.addAll(const [
          WatchlistItem(ticker: 'BBCA', isActive: true),
          WatchlistItem(ticker: 'BBRI', isActive: false),
        ]);
      Get.put(StockController(FakeAuth(hasSession: true), repository));
      await pumpPage(tester, const StockPage());

      expect(find.text('Semua 2'), findsOneWidget);
      await tester.tap(find.text('Nonaktif 1'));
      await tester.pumpAndSettle();

      expect(find.text('BBCA'), findsNothing);
      expect(find.text('BBRI'), findsOneWidget);
    });

    testWidgets('kode saham tidak valid menampilkan pesan di lembar tambah', (
      tester,
    ) async {
      Get.put(StockController(FakeAuth(hasSession: true), FakeRepository()));
      await pumpPage(tester, const StockPage());

      await tester.tap(find.byTooltip('Tambah saham'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Kode saham'),
        'BB1',
      );
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      expect(
        find.text('Kode saham harus 4 huruf, contoh BBCA.'),
        findsOneWidget,
      );
    });

    testWidgets('watchlist kosong menawarkan tombol tambah saham', (
      tester,
    ) async {
      Get.put(StockController(FakeAuth(hasSession: true), FakeRepository()));

      await pumpPage(tester, const StockPage());

      expect(find.text('Watchlist masih kosong'), findsOneWidget);
      expect(find.widgetWithText(InkWell, 'Tambah saham'), findsWidgets);
    });
  });

  group('detail', () {
    final rows = [
      rangeRow('ZP', BrokerSide.buy, 536000000000, 'Latest'),
      rangeRow('AO', BrokerSide.buy, 164200000000, 'Latest'),
      rangeRow('YP', BrokerSide.sell, 149600000000, 'Latest'),
      rangeRow('XL', BrokerSide.sell, 301900000000, 'Latest'),
      rangeRow('CC', BrokerSide.sell, 2200000000000, '1M', approx: true),
    ];

    testWidgets(
      'tab Broker: kalimat ringkas, kelompok, dan top net beli dan jual',
      (tester) async {
        final repository = FakeRepository()..rows = rows;
        Get.put(StockDetailController(repository, 'BBCA'));

        await pumpPage(tester, const StockDetailPage(), height: 2400);

        expect(
          find.text('Bandar dan Asing net beli, Ritel net jual.'),
          findsOneWidget,
        );
        expect(find.text('Top 2 net beli'), findsOneWidget);
        expect(find.text('Top 2 net jual'), findsOneWidget);
        expect(find.text('dari 2 broker'), findsNWidgets(2));
        // ZP dan XL muncul di daftar teratas dan di kartu; YP tidak punya kelompok.
        expect(find.text('ZP'), findsOneWidget);
        expect(find.text('YP'), findsOneWidget);
        expect(find.text('belum diklasifikasi'), findsWidgets);
        expect(find.text('+536,0 M'), findsWidgets);
        expect(find.text('-301,9 M'), findsWidgets);
        expect(
          find.textContaining('Belum diklasifikasi: 1 broker'),
          findsOneWidget,
        );

        await tester.tap(find.text('1M'));
        await tester.pumpAndSettle();

        expect(find.text('≈-2,20 T'), findsWidgets);
        expect(find.text('Top 1 net beli'), findsNothing);
        expect(
          find.text('Tidak ada broker net beli pada rentang ini.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('lebih dari lima broker: hanya lima teratas yang tampil', (
      tester,
    ) async {
      final repository = FakeRepository()
        ..rows = [
          for (var i = 1; i <= 8; i++)
            rangeRow('B$i', BrokerSide.buy, i * 1000000000, 'Latest'),
        ];
      Get.put(StockDetailController(repository, 'BBCA'));

      await pumpPage(tester, const StockDetailPage(), height: 2400);

      expect(find.text('Top 5 net beli'), findsOneWidget);
      expect(find.text('dari 8 broker'), findsOneWidget);
      expect(find.text('B8'), findsOneWidget);
      expect(find.text('B4'), findsOneWidget);
      expect(find.text('B3'), findsNothing);
    });

    testWidgets('tab Chart tanpa data harga: penjelasan, bukan grafik kosong', (
      tester,
    ) async {
      Get.put(StockDetailController(FakeRepository()..rows = rows, 'BBCA'));
      await pumpPage(tester, const StockDetailPage(), height: 2400);

      expect(find.text('Harga belum ada'), findsOneWidget);

      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data harga'), findsOneWidget);
      expect(find.byType(TechnicalSection), findsNothing);
    });

    testWidgets('tab Chart: harga, volume, Stoch RSI, MACD, dan pilih hari', (
      tester,
    ) async {
      final repository = FakeRepository()
        ..rows = rows
        ..bars = sampleBars(45);
      Get.put(StockDetailController(repository, 'BBCA'));
      await pumpPage(tester, const StockDetailPage(), height: 3000);

      expect(find.textContaining('PENUTUPAN'), findsOneWidget);

      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      expect(find.byType(TechnicalSection), findsOneWidget);
      expect(find.text('HARGA'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('STOCH RSI'), findsOneWidget);
      expect(find.text('MACD'), findsOneWidget);
      expect(
        find.text(
          'Sentuh atau geser di chart untuk melihat harga dan indikator tiap hari.',
        ),
        findsOneWidget,
      );
      expect(find.text('Hari terakhir'), findsNothing);

      final touch = find
          .descendant(
            of: find.byType(TechnicalSection),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is GestureDetector &&
                  widget.onHorizontalDragUpdate != null,
            ),
          )
          .first;
      await tester.drag(touch, const Offset(-60, 0));
      await tester.pumpAndSettle();

      expect(find.text('Hari terakhir'), findsOneWidget);
      expect(find.text('Buka'), findsOneWidget);

      await tester.tap(find.text('Hari terakhir'));
      await tester.pumpAndSettle();

      expect(find.text('Hari terakhir'), findsNothing);

      await tester.tap(find.text('30D'));
      await tester.pumpAndSettle();

      expect(find.byType(TechnicalSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chart dengan indikator kosong tetap tergambar tanpa galat', (
      tester,
    ) async {
      final repository = FakeRepository()
        ..bars = [
          dailyBar(
            1,
            stochA: null,
            stochB: null,
            macdA: null,
            macdB: null,
            macdHist: null,
          ),
        ];
      Get.put(StockDetailController(repository, 'BBCA'));
      await pumpPage(tester, const StockDetailPage(), height: 3000);

      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Stoch RSI belum terbaca.'), findsOneWidget);
      expect(find.text('MACD belum terbaca.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('data harga gagal: tombol coba lagi, data broker tetap ada', (
      tester,
    ) async {
      final repository = FakeRepository()
        ..rows = rows
        ..failBars = true;
      Get.put(StockDetailController(repository, 'BBCA'));
      await pumpPage(tester, const StockDetailPage(), height: 2400);

      expect(find.text('Top 2 net beli'), findsOneWidget);

      await tester.tap(find.text('Chart'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat data harga.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });
}
