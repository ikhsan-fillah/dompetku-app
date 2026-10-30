import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/daily_bar.dart';
import '../models/watchlist_item.dart';
import 'stock_auth.dart';

/// Data modul saham di Supabase. Semua tabel dikunci RLS per pengguna, jadi
/// tidak ada filter `user_id` di sisi app.
abstract interface class StockRepository {
  Future<List<WatchlistItem>> getWatchlist();

  /// Menambah saham baru ke watchlist.
  Future<void> addTicker(String ticker, {bool active = true});

  Future<void> setActive(String ticker, {required bool active});

  /// Menghapus saham dari watchlist beserta seluruh datanya (harga harian,
  /// broker, cek broker, hasil analisis) supaya database tetap ringan.
  Future<void> deleteTicker(String ticker);

  Future<BrokerGroupRules> getBrokerGroupRules();

  /// Snapshot terbaru per rentang (Latest, 7D, 1M, 3M) untuk satu saham.
  Future<List<BrokerRangeRow>> getLatestBrokerRanges(String ticker);

  /// Baris rentang Latest untuk beberapa saham sekaligus (kartu watchlist).
  Future<List<BrokerRangeRow>> getLatestRangeForTickers(List<String> tickers);

  /// Hari perdagangan terakhir satu saham, urut dari yang terlama, satu baris
  /// per tanggal. Baris bertanda `tidak_akurat` tidak ikut.
  Future<List<DailyBar>> getRecentBars(String ticker, {int limit = 90});

  /// Hari perdagangan terbaru untuk tiap saham yang diminta.
  Future<List<DailyBar>> getLatestBars(List<String> tickers);
}

/// Tabel yang menyimpan data per kode saham, ikut dihapus bersama sahamnya.
const tickerDataTables = [
  'daily_snapshot',
  'broker_range_snapshot',
  'broker_daily',
  'broker_flow_check',
  'analysis_result',
];

const _barColumns =
    'ticker, trade_date, open_price, high_price, low_price, close_price, '
    'prev_close, volume_lot, volume_ma20, stoch_rsi_a, stoch_rsi_b, macd_a, '
    'macd_b, macd_hist, is_intraday';

class SupabaseStockRepository implements StockRepository {
  SupabaseStockRepository(this._auth);

  final SupabaseStockAuth _auth;

  SupabaseClient get _client => _auth.client;

  @override
  Future<List<WatchlistItem>> getWatchlist() async {
    final rows = await _client
        .from('watchlist')
        .select('ticker, is_active, note, created_at')
        .order('created_at');
    return rows.map(WatchlistItem.fromMap).toList();
  }

  @override
  Future<void> addTicker(String ticker, {bool active = true}) async {
    await _client.from('watchlist').upsert({
      'ticker': ticker,
      'is_active': active,
    }, onConflict: 'user_id,ticker');
  }

  @override
  Future<void> setActive(String ticker, {required bool active}) async {
    await _client
        .from('watchlist')
        .update({'is_active': active})
        .eq('ticker', ticker);
  }

  @override
  Future<void> deleteTicker(String ticker) async {
    // Data dulu, watchlist terakhir: bila salah satu gagal, saham masih
    // tampil di daftar dan penghapusan bisa diulang.
    await Future.wait([
      for (final table in tickerDataTables)
        _client.from(table).delete().eq('ticker', ticker),
    ]);
    await _client.from('watchlist').delete().eq('ticker', ticker);
  }

  @override
  Future<BrokerGroupRules> getBrokerGroupRules() async {
    final rows = await _client.from('broker_group').select('broker_code, grp');
    return BrokerGroupRules.fromRows(rows);
  }

  @override
  Future<List<BrokerRangeRow>> getLatestBrokerRanges(String ticker) async {
    // Satu kueri per label, supaya label yang jarang dibaca (mis. 3M) tetap
    // ditemukan walau snapshot Latest sudah menumpuk. Satu snapshot per label
    // paling banyak sekitar 50 baris, jadi batas 100 cukup.
    final perLabel = await Future.wait([
      for (final label in brokerRangeLabels)
        _client
            .from('broker_range_snapshot')
            .select(
              'ticker, range_label, range_start, range_end, broker_code, '
              'side, value_idr, value_is_approx',
            )
            .eq('ticker', ticker)
            .eq('range_label', label)
            .order('range_end', ascending: false)
            .limit(100),
    ]);
    final rows = [
      for (final batch in perLabel) ...batch.map(BrokerRangeRow.fromMap),
    ];
    return latestSnapshotPerRange(rows);
  }

  @override
  Future<List<BrokerRangeRow>> getLatestRangeForTickers(
    List<String> tickers,
  ) async {
    if (tickers.isEmpty) return const [];
    final rows = await _client
        .from('broker_range_snapshot')
        .select(
          'ticker, range_label, range_start, range_end, broker_code, '
          'side, value_idr, value_is_approx',
        )
        .inFilter('ticker', tickers)
        .eq('range_label', 'Latest')
        .order('range_end', ascending: false)
        .limit(100 * tickers.length);
    return rows.map(BrokerRangeRow.fromMap).toList();
  }

  @override
  Future<List<DailyBar>> getRecentBars(String ticker, {int limit = 90}) async {
    final rows = await _client
        .from('daily_snapshot')
        .select(_barColumns)
        .eq('ticker', ticker)
        .neq('quality', 'tidak_akurat')
        .order('trade_date', ascending: false)
        .order('captured_at', ascending: false)
        .limit(limit * 2);
    return oneBarPerDate(rows.map(DailyBar.fromMap), limit: limit);
  }

  @override
  Future<List<DailyBar>> getLatestBars(List<String> tickers) async {
    if (tickers.isEmpty) return const [];
    final rows = await _client
        .from('daily_snapshot')
        .select(_barColumns)
        .inFilter('ticker', tickers)
        .neq('quality', 'tidak_akurat')
        .order('trade_date', ascending: false)
        .order('captured_at', ascending: false)
        .limit(10 * tickers.length);
    return rows.map(DailyBar.fromMap).toList();
  }
}
