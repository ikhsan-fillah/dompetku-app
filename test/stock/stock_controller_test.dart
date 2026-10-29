import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/features/stock/controllers/stock_controller.dart';
import 'package:dompetku_app/features/stock/controllers/stock_detail_controller.dart';
import 'package:dompetku_app/features/stock/models/broker_group.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/models/watchlist_item.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stock_fakes.dart';

void main() {
  group('StockController', () {
    test('belum dikonfigurasi: tidak memanggil Supabase', () async {
      final controller = StockController(
        FakeAuth(configured: false),
        FakeRepository(),
      );

      await controller.start();

      expect(controller.access.value, StockAccess.notConfigured);
    });

    test('tanpa sesi tersimpan: minta masuk', () async {
      final controller = StockController(FakeAuth(), FakeRepository());

      await controller.start();

      expect(controller.access.value, StockAccess.signedOut);
    });

    test('sesi tersimpan: langsung memuat watchlist', () async {
      final repository = FakeRepository()
        ..items.add(const WatchlistItem(ticker: 'BBCA', isActive: true));
      final controller = StockController(
        FakeAuth(hasSession: true),
        repository,
      );

      await controller.start();

      expect(controller.access.value, StockAccess.signedIn);
      expect(controller.watchlist.value.status, ResourceStatus.success);
      expect(controller.items.single.ticker, 'BBCA');
    });

    test('gagal memulihkan sesi (offline): kembali ke layar masuk', () async {
      final auth = FakeAuth(hasSession: true)..failRestore = true;
      final controller = StockController(auth, FakeRepository());

      await controller.start();

      expect(controller.access.value, StockAccess.signedOut);
      expect(controller.loginError.value, isNotNull);
    });

    test('masuk berhasil memuat watchlist kosong', () async {
      final controller = StockController(FakeAuth(), FakeRepository());
      await controller.start();

      final ok = await controller.signIn(' user@example.com ', 'rahasia');

      expect(ok, isTrue);
      expect(controller.access.value, StockAccess.signedIn);
      expect(controller.watchlist.value.status, ResourceStatus.empty);
    });

    test('masuk gagal menampilkan pesan dari Supabase', () async {
      final auth = FakeAuth()..signInError = 'Invalid login credentials';
      final controller = StockController(auth, FakeRepository());
      await controller.start();

      final ok = await controller.signIn('user@example.com', 'salah');

      expect(ok, isFalse);
      expect(controller.access.value, StockAccess.signedOut);
      expect(controller.loginError.value, 'Invalid login credentials');
      expect(controller.signingIn.value, isFalse);
    });

    test(
      'email atau password kosong ditolak tanpa memanggil Supabase',
      () async {
        final auth = FakeAuth()..signInError = 'tidak boleh dipanggil';
        final controller = StockController(auth, FakeRepository());

        final ok = await controller.signIn('', 'x');

        expect(ok, isFalse);
        expect(controller.loginError.value, isNot('tidak boleh dipanggil'));
      },
    );

    test(
      'menambah saham: kode dinormalkan, kode tidak valid ditolak',
      () async {
        final repository = FakeRepository();
        final controller = StockController(
          FakeAuth(hasSession: true),
          repository,
        );
        await controller.start();

        expect(await controller.addTicker(' bbca '), isNull);
        expect(await controller.addTicker('BBC'), isNotNull);
        expect(await controller.addTicker('BB1A'), isNotNull);

        expect(controller.items.map((i) => i.ticker), ['BBCA']);
      },
    );

    test('menonaktifkan saham menyimpan statusnya', () async {
      final repository = FakeRepository()
        ..items.add(const WatchlistItem(ticker: 'BBCA', isActive: true));
      final controller = StockController(
        FakeAuth(hasSession: true),
        repository,
      );
      await controller.start();

      final ok = await controller.setActive(controller.items.single, false);

      expect(ok, isTrue);
      expect(controller.items.single.isActive, isFalse);
    });

    test('gagal memuat watchlist menjadi status error', () async {
      final repository = FakeRepository()..fail = true;
      final controller = StockController(
        FakeAuth(hasSession: true),
        repository,
      );

      await controller.start();

      expect(controller.watchlist.value.status, ResourceStatus.error);
    });

    test(
      'ringkasan watchlist: arah dana kelompok dan harga per saham',
      () async {
        final repository = FakeRepository()
          ..items.addAll(const [
            WatchlistItem(ticker: 'BBCA', isActive: true),
            WatchlistItem(ticker: 'BBRI', isActive: false),
          ])
          ..rows = [
            rangeRow('ZP', BrokerSide.buy, 536000000000, 'Latest'),
            rangeRow('XL', BrokerSide.sell, 300000000000, 'Latest'),
            rangeRow('ZP', BrokerSide.buy, 1, '7D'),
          ]
          ..bars = [dailyBar(1), dailyBar(2, close: 9100)];
        final controller = StockController(
          FakeAuth(hasSession: true),
          repository,
        );

        await controller.start();

        final bbca = controller.overviews['BBCA']!;
        expect(bbca.flow!.of(BrokerGroup.asing).netIdr, 536000000000);
        expect(bbca.flow!.of(BrokerGroup.ritel).netIdr, -300000000000);
        expect(bbca.flowDate, DateTime(2026, 10, 28));
        expect(bbca.bar!.close, 9100);
        final bbri = controller.overviews['BBRI']!;
        expect(bbri.flow, isNull);
        expect(bbri.bar, isNull);
        expect(controller.latestFlowDate, DateTime(2026, 10, 28));
      },
    );

    test(
      'ringkasan gagal dimuat: daftar tetap tampil tanpa ringkasan',
      () async {
        final repository = FakeRepository()
          ..items.add(const WatchlistItem(ticker: 'BBCA', isActive: true))
          ..failOverviews = true;
        final controller = StockController(
          FakeAuth(hasSession: true),
          repository,
        );

        await controller.start();

        expect(controller.watchlist.value.status, ResourceStatus.success);
        expect(controller.overviews, isEmpty);
      },
    );

    test('penyaring memisahkan saham aktif dan nonaktif', () async {
      final repository = FakeRepository()
        ..items.addAll(const [
          WatchlistItem(ticker: 'BBCA', isActive: true),
          WatchlistItem(ticker: 'BBRI', isActive: false),
          WatchlistItem(ticker: 'TLKM', isActive: true),
        ]);
      final controller = StockController(
        FakeAuth(hasSession: true),
        repository,
      );
      await controller.start();

      expect(controller.visibleItems, hasLength(3));
      expect(controller.activeCount, 2);

      controller.setFilter(WatchFilter.inactive);
      expect(controller.visibleItems.map((i) => i.ticker), ['BBRI']);

      controller.setFilter(WatchFilter.active);
      expect(controller.visibleItems.map((i) => i.ticker), ['BBCA', 'TLKM']);
    });

    test('keluar mengosongkan watchlist dan kembali ke layar masuk', () async {
      final controller = StockController(
        FakeAuth(hasSession: true),
        FakeRepository(),
      );
      await controller.start();

      await controller.signOut();

      expect(controller.access.value, StockAccess.signedOut);
      expect(controller.watchlist.value.status, ResourceStatus.idle);
    });
  });

  group('StockDetailController', () {
    test('total kelompok mengikuti rentang yang dipilih', () async {
      final repository = FakeRepository()
        ..rows = [
          rangeRow('ZP', BrokerSide.buy, 536000000000, 'Latest'),
          rangeRow('ZP', BrokerSide.buy, 80600000000, '7D'),
          rangeRow('YP', BrokerSide.sell, 149600000000, 'Latest'),
        ];
      final controller = StockDetailController(repository, 'BBCA');
      await controller.load();

      expect(controller.summary.of(BrokerGroup.asing).netIdr, 536000000000);
      expect(controller.summary.unclassified.netIdr, -149600000000);

      controller.selectRange('7D');

      expect(controller.summary.of(BrokerGroup.asing).netIdr, 80600000000);
      expect(controller.summary.unclassified.brokerCount, 0);
    });

    test('baris urut: net beli dulu, nilai terbesar di atas', () async {
      final repository = FakeRepository()
        ..rows = [
          rangeRow('AA', BrokerSide.sell, 5, 'Latest'),
          rangeRow('BB', BrokerSide.buy, 10, 'Latest'),
          rangeRow('CC', BrokerSide.buy, 30, 'Latest'),
          rangeRow('DD', BrokerSide.sell, 50, 'Latest'),
        ];
      final controller = StockDetailController(repository, 'BBCA');
      await controller.load();

      expect(controller.rowsInRange.map((r) => r.brokerCode), [
        'CC',
        'BB',
        'DD',
        'AA',
      ]);
    });

    test(
      'daftar teratas: lima terbesar per sisi, total sisi tetap utuh',
      () async {
        final repository = FakeRepository()
          ..rows = [
            for (var i = 1; i <= 7; i++)
              rangeRow('B$i', BrokerSide.buy, i * 10, 'Latest'),
            for (var i = 1; i <= 3; i++)
              rangeRow('S$i', BrokerSide.sell, i * 100, 'Latest'),
          ];
        final controller = StockDetailController(repository, 'BBCA');
        await controller.load();

        expect(controller.topBuyers.map((r) => r.brokerCode), [
          'B7',
          'B6',
          'B5',
          'B4',
          'B3',
        ]);
        expect(controller.buyers, hasLength(7));
        expect(controller.topSellers.map((r) => r.brokerCode), [
          'S3',
          'S2',
          'S1',
        ]);
      },
    );

    test('data harga: panjang chart mengikuti pilihan hari', () async {
      final repository = FakeRepository()..bars = sampleBars(80);
      final controller = StockDetailController(repository, 'BBCA');
      await controller.load();

      expect(controller.bars.value.status, ResourceStatus.success);
      expect(controller.latestBar!.tradeDate, repository.bars.last.tradeDate);
      expect(controller.chartDays.value, 60);
      expect(controller.visibleBars, hasLength(60));

      controller.selectChartDays(30);
      expect(controller.visibleBars, hasLength(30));
      expect(controller.visibleBars.last, repository.bars.last);

      controller.selectChartDays(90);
      expect(controller.visibleBars, hasLength(80));
    });

    test('data harga gagal tidak menggagalkan data broker', () async {
      final repository = FakeRepository()
        ..rows = [rangeRow('ZP', BrokerSide.buy, 10, 'Latest')]
        ..failBars = true;
      final controller = StockDetailController(repository, 'BBCA');

      await controller.load();

      expect(controller.state.value.status, ResourceStatus.success);
      expect(controller.bars.value.status, ResourceStatus.error);
    });

    test('tab bawaan Broker, bisa pindah ke Chart', () {
      final controller = StockDetailController(FakeRepository(), 'BBCA');

      expect(controller.tab.value, DetailTab.broker);
      controller.selectTab(DetailTab.chart);
      expect(controller.tab.value, DetailTab.chart);
    });

    test('tanpa data: status empty; gagal: status error', () async {
      final repository = FakeRepository();
      final controller = StockDetailController(repository, 'BBCA');

      await controller.load();
      expect(controller.state.value.status, ResourceStatus.empty);

      repository.fail = true;
      await controller.load();
      expect(controller.state.value.status, ResourceStatus.error);
      expect(controller.bars.value.status, ResourceStatus.empty);
    });
  });
}
