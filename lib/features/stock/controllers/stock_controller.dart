import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../data/stock_auth.dart';
import '../data/stock_repository.dart';
import '../models/watchlist_item.dart';

enum StockAccess { checking, notConfigured, signedOut, signedIn }

/// Login ke Supabase dan daftar watchlist untuk modul saham.
class StockController extends GetxController {
  StockController(this._auth, this._repository);

  final StockAuth _auth;
  final StockRepository _repository;

  final access = StockAccess.checking.obs;
  final watchlist = const ResourceState<List<WatchlistItem>>.idle().obs;
  final signingIn = false.obs;
  final loginError = RxnString();

  String? get email => _auth.email;

  List<WatchlistItem> get items =>
      watchlist.value.data ?? const <WatchlistItem>[];

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
    access.value = StockAccess.signedOut;
  }

  Future<void> load() async {
    if (watchlist.value.status != ResourceStatus.success) {
      watchlist.value = const ResourceState.loading();
    }
    try {
      final items = await _repository.getWatchlist();
      watchlist.value = items.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(items);
    } catch (_) {
      watchlist.value = ResourceState.error('Gagal memuat watchlist.'.tr);
    }
  }

  /// Menambah saham. Mengembalikan pesan kesalahan, atau null bila berhasil.
  Future<String?> addTicker(String raw) async {
    final ticker = normalizeTicker(raw);
    if (ticker == null) return 'Kode saham harus 4 huruf, contoh BBCA.'.tr;
    try {
      await _repository.addTicker(ticker);
      await load();
      return null;
    } catch (_) {
      return 'Gagal menambah saham.'.tr;
    }
  }

  /// Mengaktifkan atau menonaktifkan saham. Mengembalikan false bila gagal.
  Future<bool> setActive(WatchlistItem item, bool active) async {
    try {
      await _repository.setActive(item.ticker, active: active);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
