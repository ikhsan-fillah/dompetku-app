import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/daily_bar.dart';
import '../models/ml_cycle.dart';
import '../models/ml_prediction.dart';
import '../models/news_score.dart';
import '../models/price_point.dart';
import '../models/vol_forecast.dart';
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

  /// Riwayat harga harian dari `price_history` (sumber pipeline ML), urut
  /// dari yang terlama, paling banyak [limit] hari bursa terakhir. Dipakai
  /// untuk MA50, MA200, volatilitas, dan IHSG (kode `^JKSE`).
  Future<List<PricePoint>> getPriceHistory(String ticker, {int limit = 260});

  /// Skor kata berita pasar untuk hari terbit [day] (WIB), null bila belum
  /// ada judul yang punya skor.
  Future<NewsScore?> getNewsScore(DateTime day);

  /// Prediksi ML terbaru satu saham dari model yang aktif, null bila belum
  /// ada. Hasilnya penyaring, bukan rekomendasi beli atau jual.
  Future<MlPrediction?> getLatestPrediction(String ticker);

  /// Prediksi terbaru dari model aktif yang hasil nyatanya sudah dihitung,
  /// null bila belum ada yang genap horizon hari bursa.
  Future<MlPrediction?> getLatestMaturedPrediction(String ticker);

  /// Riwayat prediksi satu saham dari model aktif, satu baris per tanggal
  /// sinyal, terbaru dulu, paling banyak [limit]. Tiap baris menyimpan
  /// tanggal sinyalnya sendiri, jadi jendela 10 hari tiap prediksi tetap.
  Future<List<MlPrediction>> getPredictionHistory(
    String ticker, {
    int limit = 10,
  });

  /// Siklus 10 hari bursa satu saham (tabel `ml_cycle`), terbaru dulu, paling
  /// banyak [limit]. Kosong bila belum ada siklus.
  Future<List<MlCycle>> getCycleHistory(String ticker, {int limit = 10});

  /// Prediksi pada tanggal sinyal [date] dari model [modelVersion], tanpa
  /// menyaring model aktif: siklus lama tetap memakai model saat itu. Null
  /// bila saham itu tidak ikut pipeline harian pada tanggal tersebut.
  Future<MlPrediction?> getPredictionOn(
    String ticker,
    DateTime date,
    String modelVersion,
  );

  /// Perkiraan gerak harian terbaru satu saham (tabel `ml_vol`), null bila
  /// belum pernah dihitung.
  Future<VolForecast?> getLatestVolForecast(String ticker);
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

/// Kolom prediksi ML beserta model tersemat. `!inner` dipakai supaya filter
/// `ml_model.is_active` ikut menyaring baris prediksi model lama.
const _mlColumns =
    'ticker, trade_date, model_version, horizon_days, prob_up, base_rate, '
    'signal, upper_pct, lower_pct, close_price, drivers, outcome_date, '
    'outcome_entry, outcome_exit, outcome_ret_net, outcome_win, '
    'outcome_hit_upper, ml_model!inner(trained_at, metrics, is_active, universe)';

/// Kolom ringkas untuk riwayat: tanpa metrik dan daftar saham model, yang
/// besar dan sama di semua baris. `!inner` tetap dipakai untuk menyaring
/// prediksi model lama.
const _mlHistoryColumns =
    'ticker, trade_date, model_version, horizon_days, prob_up, base_rate, '
    'signal, upper_pct, lower_pct, close_price, drivers, outcome_date, '
    'outcome_entry, outcome_exit, outcome_ret_net, outcome_win, '
    'outcome_hit_upper, ml_model!inner(is_active)';

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

  @override
  Future<List<PricePoint>> getPriceHistory(
    String ticker, {
    int limit = 260,
  }) async {
    // Server membatasi satu permintaan sampai 1000 baris, jadi riwayat yang
    // lebih panjang diambil per halaman, terbaru dulu.
    const page = 1000;
    final points = <PricePoint>[];
    for (var from = 0; from < limit; from += page) {
      final take = limit - from < page ? limit - from : page;
      final rows = await _client
          .from('price_history')
          .select(
            'ticker, trade_date, open_price, high_price, low_price, '
            'close_price, volume',
          )
          .eq('ticker', ticker)
          .order('trade_date', ascending: false)
          .range(from, from + take - 1);
      points.addAll([for (final row in rows) ?PricePoint.tryFromMap(row)]);
      if (rows.length < take) break;
    }
    return points.reversed.toList();
  }

  @override
  Future<NewsScore?> getNewsScore(DateTime day) async {
    // Batas hari WIB (UTC+7) dalam UTC.
    final start = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).subtract(const Duration(hours: 7));
    final rows = await _client
        .from('market_news')
        .select('sentiment')
        .gte('published_at', start.toIso8601String())
        .lt(
          'published_at',
          start.add(const Duration(days: 1)).toIso8601String(),
        )
        .limit(2000);
    return NewsScore.fromSentiments(day, [
      for (final row in rows) row['sentiment'],
    ]);
  }

  @override
  Future<MlPrediction?> getLatestPrediction(String ticker) async {
    // Hanya prediksi dari model aktif. Kolom model ikut dibaca untuk tanggal
    // latih dan AUC per lipatan uji.
    final rows = await _client
        .from('ml_prediction')
        .select(_mlColumns)
        .eq('ticker', ticker)
        .eq('ml_model.is_active', true)
        .order('trade_date', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return MlPrediction.tryFromMap(rows.first);
  }

  @override
  Future<MlPrediction?> getLatestMaturedPrediction(String ticker) async {
    final rows = await _client
        .from('ml_prediction')
        .select(_mlColumns)
        .eq('ticker', ticker)
        .eq('ml_model.is_active', true)
        .not('outcome_ret_net', 'is', null)
        .order('trade_date', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return MlPrediction.tryFromMap(rows.first);
  }

  @override
  Future<List<MlPrediction>> getPredictionHistory(
    String ticker, {
    int limit = 10,
  }) async {
    final rows = await _client
        .from('ml_prediction')
        .select(_mlHistoryColumns)
        .eq('ticker', ticker)
        .eq('ml_model.is_active', true)
        .order('trade_date', ascending: false)
        .limit(limit);
    return [for (final row in rows) ?MlPrediction.tryFromMap(row)];
  }

  @override
  Future<List<MlCycle>> getCycleHistory(String ticker, {int limit = 10}) async {
    final rows = await _client
        .from('ml_cycle')
        .select()
        .eq('ticker', ticker)
        .order('cycle_start', ascending: false)
        .limit(limit);
    return [for (final row in rows) ?MlCycle.tryFromMap(row)];
  }

  @override
  Future<VolForecast?> getLatestVolForecast(String ticker) async {
    final rows = await _client
        .from('ml_vol')
        .select()
        .eq('ticker', ticker)
        .order('as_of', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return VolForecast.tryFromMap(rows.first);
  }

  @override
  Future<MlPrediction?> getPredictionOn(
    String ticker,
    DateTime date,
    String modelVersion,
  ) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final rows = await _client
        .from('ml_prediction')
        .select(_mlColumns)
        .eq('ticker', ticker)
        .eq('trade_date', day)
        .eq('model_version', modelVersion)
        .limit(1);
    if (rows.isEmpty) return null;
    return MlPrediction.tryFromMap(rows.first);
  }
}
