import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/watchlist_item.dart';
import 'stock_auth.dart';

/// Data modul saham di Supabase. Semua tabel dikunci RLS per pengguna, jadi
/// tidak ada filter `user_id` di sisi app.
abstract interface class StockRepository {
  Future<List<WatchlistItem>> getWatchlist();

  /// Menambah saham, atau mengaktifkan kembali bila sudah ada.
  Future<void> addTicker(String ticker);

  Future<void> setActive(String ticker, {required bool active});

  Future<BrokerGroupRules> getBrokerGroupRules();

  /// Snapshot terbaru per rentang (Latest, 7D, 1M, 3M) untuk satu saham.
  Future<List<BrokerRangeRow>> getLatestBrokerRanges(String ticker);
}

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
  Future<void> addTicker(String ticker) async {
    await _client.from('watchlist').upsert({
      'ticker': ticker,
      'is_active': true,
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
}
