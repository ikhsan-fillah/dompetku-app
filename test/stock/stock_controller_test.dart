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

    test('tanpa data: status empty; gagal: status error', () async {
      final repository = FakeRepository();
      final controller = StockDetailController(repository, 'BBCA');

      await controller.load();
      expect(controller.state.value.status, ResourceStatus.empty);

      repository.fail = true;
      await controller.load();
      expect(controller.state.value.status, ResourceStatus.error);
    });
  });
}
