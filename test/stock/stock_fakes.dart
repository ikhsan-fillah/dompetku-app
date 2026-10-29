import 'package:dompetku_app/features/stock/data/stock_auth.dart';
import 'package:dompetku_app/features/stock/data/stock_repository.dart';
import 'package:dompetku_app/features/stock/models/broker_group.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
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

  @override
  Future<List<WatchlistItem>> getWatchlist() async {
    if (fail) throw Exception('boom');
    return List.of(items);
  }

  @override
  Future<void> addTicker(String ticker) async {
    if (fail) throw Exception('boom');
    items.removeWhere((i) => i.ticker == ticker);
    items.add(WatchlistItem(ticker: ticker, isActive: true));
  }

  @override
  Future<void> setActive(String ticker, {required bool active}) async {
    if (fail) throw Exception('boom');
    final index = items.indexWhere((i) => i.ticker == ticker);
    items[index] = items[index].copyWith(isActive: active);
  }

  List<BrokerRangeRow> rows = [];

  @override
  Future<BrokerGroupRules> getBrokerGroupRules() async =>
      const BrokerGroupRules({'ZP': BrokerGroup.asing});

  @override
  Future<List<BrokerRangeRow>> getLatestBrokerRanges(String ticker) async {
    if (fail) throw Exception('boom');
    return rows;
  }
}

BrokerRangeRow rangeRow(
  String code,
  BrokerSide side,
  int idr,
  String label, {
  bool approx = false,
}) => BrokerRangeRow(
  ticker: 'BBCA',
  rangeLabel: label,
  rangeStart: DateTime(2026, 10, 22),
  rangeEnd: DateTime(2026, 10, 28),
  brokerCode: code,
  side: side,
  valueIdr: idr,
  isApprox: approx,
);
