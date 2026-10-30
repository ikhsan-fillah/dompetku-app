import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../data/stock_auth.dart';
import '../data/stock_repository.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/daily_bar.dart';
import '../models/watchlist_item.dart';
import '../services/broker_group_calculator.dart';

enum StockAccess { checking, notConfigured, signedOut, signedIn }

/// Penyaring daftar watchlist.
enum WatchFilter { all, active, inactive }

/// Batas saham aktif. Hanya saham aktif yang diambil datanya otomatis, jadi
/// batas ini menjaga pengambilan harian tetap kecil.
const maxActiveTickers = 5;

/// Saham aktif di atas (urutan tambah tetap), nonaktif di bawahnya.
List<WatchlistItem> activeFirst(Iterable<WatchlistItem> items) => [
  for (final item in items)
    if (item.isActive) item,
  for (final item in items)
    if (!item.isActive) item,
];

/// Ringkasan satu saham untuk kartu watchlist: arah dana kelompok pada
/// snapshot Latest terbaru dan harga penutupan terbaru. Keduanya boleh kosong
/// bila datanya belum diisi.
class TickerOverview {
  const TickerOverview({this.flow, this.flowDate, this.bar});

  final GroupSummary? flow;
  final DateTime? flowDate;
  final DailyBar? bar;
}

/// Login ke Supabase dan daftar watchlist untuk modul saham.
class StockController extends GetxController {
  StockController(
    this._auth,
    this._repository, {
    BrokerGroupCalculator calculator = const BrokerGroupCalculator(),
  }) : _calculator = calculator;

  final StockAuth _auth;
  final StockRepository _repository;
  final BrokerGroupCalculator _calculator;

  final access = StockAccess.checking.obs;
  final watchlist = const ResourceState<List<WatchlistItem>>.idle().obs;
  final signingIn = false.obs;
  final loginError = RxnString();
  final filter = WatchFilter.all.obs;
  final overviews = <String, TickerOverview>{}.obs;

  String? get email => _auth.email;

  List<WatchlistItem> get items =>
      watchlist.value.data ?? const <WatchlistItem>[];

  /// Saham yang lolos penyaring terpilih.
  List<WatchlistItem> get visibleItems => switch (filter.value) {
    WatchFilter.all => items,
    WatchFilter.active => [
      for (final item in items)
        if (item.isActive) item,
    ],
    WatchFilter.inactive => [
      for (final item in items)
        if (!item.isActive) item,
    ],
  };

  int get activeCount => items.where((item) => item.isActive).length;

  /// True bila kelima slot aktif sudah terisi.
  bool get slotsFull => activeCount >= maxActiveTickers;

  /// Tanggal data broker terbaru di antara semua saham, null bila belum ada.
  DateTime? get latestFlowDate => overviews.values
      .map((overview) => overview.flowDate)
      .nonNulls
      .fold<DateTime?>(
        null,
        (best, date) => best == null || date.isAfter(best) ? date : best,
      );

  @override
  void onInit() {
    super.onInit();
    start();
  }

  /// Memeriksa konfigurasi dan sesi tersimpan, lalu memuat watchlist.
  Future<void> start() async {
    access.value = StockAccess.checking;
    if (!_auth.isConfigured) {
      access.value = StockAccess.notConfigured;
      return;
    }
    try {
      final signedIn = await _auth.restoreSession();
      access.value = signedIn ? StockAccess.signedIn : StockAccess.signedOut;
      if (signedIn) await load();
    } catch (_) {
      // Tanpa koneksi atau Supabase tidak terjangkau: minta masuk lagi daripada
      // menahan layar di status memeriksa.
      access.value = StockAccess.signedOut;
      loginError.value = 'Tidak bisa terhubung ke Supabase.'.tr;
    }
  }

  Future<bool> signIn(String email, String password) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      loginError.value = 'Email dan password wajib diisi.'.tr;
      return false;
    }
    signingIn.value = true;
    loginError.value = null;
    try {
      await _auth.signIn(email: trimmed, password: password);
      access.value = StockAccess.signedIn;
      await load();
      return true;
    } on StockAuthException catch (error) {
      loginError.value = error.message;
      return false;
    } catch (_) {
      loginError.value = 'Tidak bisa terhubung ke Supabase.'.tr;
      return false;
    } finally {
      signingIn.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Sesi lokal tetap dianggap berakhir; token di server kedaluwarsa sendiri.
    }
    watchlist.value = const ResourceState.idle();
    overviews.clear();
    access.value = StockAccess.signedOut;
  }

  Future<void> load() async {
    if (watchlist.value.status != ResourceStatus.success) {
      watchlist.value = const ResourceState.loading();
    }
    try {
      final items = activeFirst(await _repository.getWatchlist());
      watchlist.value = items.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(items);
      if (items.isNotEmpty) await _loadOverviews(items);
    } catch (_) {
      watchlist.value = ResourceState.error('Gagal memuat watchlist.'.tr);
    }
  }

  /// Melengkapi kartu watchlist. Gagal di sini tidak menggagalkan daftar:
  /// kartu tetap tampil, hanya tanpa ringkasan.
  Future<void> _loadOverviews(List<WatchlistItem> items) async {
    final tickers = [for (final item in items) item.ticker];
    try {
      final results = await Future.wait([
        _repository.getLatestRangeForTickers(tickers),
        _repository.getLatestBars(tickers),
        _repository.getBrokerGroupRules(),
      ]);
      final rows = results[0] as List<BrokerRangeRow>;
      final bars = latestBarPerTicker(results[1] as List<DailyBar>);
      final rules = results[2] as BrokerGroupRules;
      overviews.assignAll({
        for (final ticker in tickers)
          ticker: _overviewOf(
            [
              for (final row in rows)
                if (row.ticker == ticker) row,
            ],
            bars[ticker],
            rules,
          ),
      });
    } catch (_) {
      overviews.clear();
    }
  }

  TickerOverview _overviewOf(
    List<BrokerRangeRow> rows,
    DailyBar? bar,
    BrokerGroupRules rules,
  ) {
    final latest = latestSnapshotPerRange(rows);
    return TickerOverview(
      flow: latest.isEmpty ? null : _calculator.summarize(latest, rules),
      flowDate: latest.isEmpty ? null : latest.first.rangeEnd,
      bar: bar,
    );
  }

  void setFilter(WatchFilter value) => filter.value = value;

  void clearLoginError() => loginError.value = null;

  /// Menambah saham. Saham baru langsung aktif bila masih ada slot, dan
  /// masuk sebagai nonaktif bila kelima slot terisi. Mengembalikan pesan
  /// kesalahan, atau null bila berhasil.
  Future<String?> addTicker(String raw) async {
    final ticker = normalizeTicker(raw);
    if (ticker == null) return 'Kode saham harus 4 huruf, contoh BBCA.'.tr;
    if (items.any((item) => item.ticker == ticker)) {
      return '@ticker sudah ada di watchlist.'.trParams({'ticker': ticker});
    }
    try {
      await _repository.addTicker(ticker, active: !slotsFull);
      await load();
      return null;
    } catch (_) {
      return 'Gagal menambah saham.'.tr;
    }
  }

  /// Mengaktifkan atau menonaktifkan saham. Mengembalikan pesan kesalahan,
  /// atau null bila berhasil. Mengaktifkan ditolak bila slot sudah penuh.
  Future<String?> setActive(WatchlistItem item, bool active) async {
    if (active && !item.isActive && slotsFull) {
      return 'Slot aktif penuh (@max/@max). Nonaktifkan satu saham dulu.'
          .trParams({'max': '$maxActiveTickers'});
    }
    try {
      await _repository.setActive(item.ticker, active: active);
      await load();
      return null;
    } catch (_) {
      return 'Gagal mengubah status saham.'.tr;
    }
  }

  /// Menghapus saham beserta seluruh datanya di Supabase. Mengembalikan
  /// false bila gagal.
  Future<bool> deleteTicker(WatchlistItem item) async {
    try {
      await _repository.deleteTicker(item.ticker);
      overviews.remove(item.ticker);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
