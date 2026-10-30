import 'package:dompetku_app/features/stock/data/stock_auth.dart';
import 'package:dompetku_app/features/stock/data/stock_repository.dart';
import 'package:dompetku_app/features/stock/models/broker_group.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/models/daily_bar.dart';
import 'package:dompetku_app/features/stock/models/watchlist_item.dart';

class FakeAuth implements StockAuth {
  FakeAuth({this.configured = true, this.hasSession = false});

  final bool configured;
  bool hasSession;
  bool failRestore = false;
  String? signInError;

  @override
  bool get isConfigured => configured;

  @override
  String? get email => hasSession ? 'user@example.com' : null;

  @override
  Future<bool> restoreSession() async {
    if (failRestore) throw Exception('offline');
    return hasSession;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError != null) throw StockAuthException(signInError!);
    hasSession = true;
  }

  @override
  Future<void> signOut() async => hasSession = false;
}

class FakeRepository implements StockRepository {
  final items = <WatchlistItem>[];
  bool fail = false;

  /// Baris broker semua rentang. Dipakai untuk detail dan ringkasan watchlist.
  List<BrokerRangeRow> rows = [];

  /// Hari perdagangan, terlama dulu.
  List<DailyBar> bars = [];
  bool failBars = false;
  bool failOverviews = false;

  @override
  Future<List<WatchlistItem>> getWatchlist() async {
    if (fail) throw Exception('boom');
    return List.of(items);
  }

  @override
  Future<void> addTicker(String ticker, {bool active = true}) async {
    if (fail) throw Exception('boom');
    items.removeWhere((i) => i.ticker == ticker);
    items.add(WatchlistItem(ticker: ticker, isActive: active));
  }

  /// Saham yang dihapus beserta datanya, urut sesuai panggilan.
  final deleted = <String>[];

  @override
  Future<void> deleteTicker(String ticker) async {
    if (fail) throw Exception('boom');
    deleted.add(ticker);
    items.removeWhere((i) => i.ticker == ticker);
    rows = [
      for (final row in rows)
        if (row.ticker != ticker) row,
    ];
    bars = [
      for (final bar in bars)
        if (bar.ticker != ticker) bar,
    ];
  }

  @override
  Future<void> setActive(String ticker, {required bool active}) async {
    if (fail) throw Exception('boom');
    final index = items.indexWhere((i) => i.ticker == ticker);
    items[index] = items[index].copyWith(isActive: active);
  }

  @override
  Future<BrokerGroupRules> getBrokerGroupRules() async =>
      const BrokerGroupRules({
        'ZP': BrokerGroup.asing,
        'XL': BrokerGroup.ritel,
        'AO': BrokerGroup.bandar,
      });

  @override
  Future<List<BrokerRangeRow>> getLatestBrokerRanges(String ticker) async {
    if (fail) throw Exception('boom');
    return rows;
  }

  @override
  Future<List<BrokerRangeRow>> getLatestRangeForTickers(
    List<String> tickers,
  ) async {
    if (failOverviews) throw Exception('boom');
    return [
      for (final row in rows)
        if (row.rangeLabel == 'Latest' && tickers.contains(row.ticker)) row,
    ];
  }

  @override
  Future<List<DailyBar>> getRecentBars(String ticker, {int limit = 90}) async {
    if (failBars) throw Exception('boom');
    final own = [
      for (final bar in bars)
        if (bar.ticker == ticker) bar,
    ];
    return own.length <= limit ? own : own.sublist(own.length - limit);
  }

  @override
  Future<List<DailyBar>> getLatestBars(List<String> tickers) async => [
    for (final bar in bars)
      if (tickers.contains(bar.ticker)) bar,
  ];
}

BrokerRangeRow rangeRow(
  String code,
  BrokerSide side,
  int idr,
  String label, {
  bool approx = false,
  String ticker = 'BBCA',
}) => BrokerRangeRow(
  ticker: ticker,
  rangeLabel: label,
  rangeStart: DateTime(2026, 10, 22),
  rangeEnd: DateTime(2026, 10, 28),
  brokerCode: code,
  side: side,
  valueIdr: idr,
  isApprox: approx,
);

/// Hari perdagangan contoh. Hanya dipakai di tes; angkanya bukan data pasar.
DailyBar dailyBar(
  int day, {
  String ticker = 'BBCA',
  int close = 9000,
  int? open,
  int? high,
  int? low,
  int prevClose = 8950,
  int volumeLot = 5000000,
  int volumeMa20 = 6000000,
  double? stochA = 50,
  double? stochB = 55,
  double? macdA = -10,
  double? macdB = -12,
  double? macdHist = 2,
  bool isIntraday = false,
}) => DailyBar(
  ticker: ticker,
  tradeDate: DateTime(2026, 10, 1).add(Duration(days: day)),
  open: open ?? close - 20,
  high: high ?? close + 40,
  low: low ?? close - 50,
  close: close,
  prevClose: prevClose,
  volumeLot: volumeLot,
  volumeMa20: volumeMa20,
  stochA: stochA,
  stochB: stochB,
  macdA: macdA,
  macdB: macdB,
  macdHist: macdHist,
  isIntraday: isIntraday,
);

/// Deret [count] hari dengan harga naik turun dan indikator yang bergerak.
List<DailyBar> sampleBars(int count, {String ticker = 'BBCA'}) => [
  for (var i = 0; i < count; i++)
    dailyBar(
      i,
      ticker: ticker,
      close: 9000 + (i % 7) * 25 - (i % 3) * 30,
      prevClose: 9000 + ((i - 1) % 7) * 25 - ((i - 1) % 3) * 30,
      volumeLot: 4000000 + (i % 5) * 900000,
      stochA: 20.0 + (i * 7) % 70,
      stochB: 25.0 + (i * 5) % 60,
      macdA: -50.0 + i,
      macdB: -60.0 + i * 1.1,
      macdHist: (i % 2 == 0 ? 1 : -1) * (3 + i % 4).toDouble(),
    ),
];
