import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../data/stock_repository.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/daily_bar.dart';
import '../services/broker_group_calculator.dart';

/// Data satu saham: baris per broker dan aturan kelompok.
class StockDetailData {
  const StockDetailData({required this.rows, required this.rules});

  final List<BrokerRangeRow> rows;
  final BrokerGroupRules rules;
}

/// Dua tab halaman detail: arus dana broker, dan chart dengan indikator.
enum DetailTab { broker, chart }

/// Panjang chart yang bisa dipilih, dalam hari perdagangan.
const chartDayOptions = [30, 60, 90];

/// Berapa broker yang ditampilkan di tiap daftar teratas.
const topBrokerCount = 5;

/// Tampilan satu saham: arus dana per broker dengan total kelompok yang
/// dihitung di app, serta chart harga dan indikator.
class StockDetailController extends GetxController {
  StockDetailController(
    this._repository,
    this.ticker, {
    BrokerGroupCalculator calculator = const BrokerGroupCalculator(),
  }) : _calculator = calculator;

  final StockRepository _repository;
  final BrokerGroupCalculator _calculator;
  final String ticker;

  final state = const ResourceState<StockDetailData>.idle().obs;
  final bars = const ResourceState<List<DailyBar>>.idle().obs;
  final range = brokerRangeLabels.first.obs;
  final tab = DetailTab.broker.obs;
  final chartDays = chartDayOptions[1].obs;

  StockDetailData? get data => state.value.data;

  /// Hari perdagangan yang digambar: [chartDays] terakhir, terlama dulu.
  List<DailyBar> get visibleBars {
    final all = bars.value.data ?? const <DailyBar>[];
    final count = chartDays.value;
    return all.length <= count ? all : all.sublist(all.length - count);
  }

  /// Hari terakhir yang punya data, null bila tabel harga masih kosong.
  DailyBar? get latestBar => bars.value.data?.lastOrNull;

  /// Baris rentang terpilih: net beli dulu, tiap sisi dari nilai terbesar.
  List<BrokerRangeRow> get rowsInRange {
    final rows = [
      for (final row in data?.rows ?? const <BrokerRangeRow>[])
        if (row.rangeLabel == range.value) row,
    ];
    rows.sort((a, b) {
      if (a.side != b.side) return a.side == BrokerSide.buy ? -1 : 1;
      return b.valueIdr.compareTo(a.valueIdr);
    });
    return rows;
  }

  List<BrokerRangeRow> _side(BrokerSide side) => [
    for (final row in rowsInRange)
      if (row.side == side) row,
  ];

  /// Seluruh broker net beli pada rentang terpilih, terbesar dulu.
  List<BrokerRangeRow> get buyers => _side(BrokerSide.buy);

  /// Seluruh broker net jual pada rentang terpilih, terbesar dulu.
  List<BrokerRangeRow> get sellers => _side(BrokerSide.sell);

  List<BrokerRangeRow> get topBuyers => buyers.take(topBrokerCount).toList();

  List<BrokerRangeRow> get topSellers => sellers.take(topBrokerCount).toList();

  GroupSummary get summary => _calculator.summarize(
    rowsInRange,
    data?.rules ?? const BrokerGroupRules.empty(),
  );

  /// Tanggal awal dan akhir rentang terpilih, null bila tidak ada data.
  (DateTime, DateTime)? get period {
    final rows = rowsInRange;
    if (rows.isEmpty) return null;
    return (rows.first.rangeStart, rows.first.rangeEnd);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Memuat data broker dan data harga bersamaan. Keduanya gagal sendiri-
  /// sendiri, jadi chart tetap tampil bila data broker bermasalah.
  Future<void> load() => Future.wait([loadBrokers(), loadBars()]);

  Future<void> loadBrokers() async {
    state.value = const ResourceState.loading();
    try {
      final results = await Future.wait([
        _repository.getLatestBrokerRanges(ticker),
        _repository.getBrokerGroupRules(),
      ]);
      final rows = results[0] as List<BrokerRangeRow>;
      final rules = results[1] as BrokerGroupRules;
      state.value = rows.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(StockDetailData(rows: rows, rules: rules));
    } catch (_) {
      state.value = ResourceState.error('Gagal memuat data broker.'.tr);
    }
  }

  Future<void> loadBars() async {
    bars.value = const ResourceState.loading();
    try {
      final rows = await _repository.getRecentBars(
        ticker,
        limit: chartDayOptions.last,
      );
      bars.value = rows.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(rows);
    } catch (_) {
      bars.value = ResourceState.error('Gagal memuat data harga.'.tr);
    }
  }

  void selectRange(String label) => range.value = label;

  void selectTab(DetailTab value) => tab.value = value;

  void selectChartDays(int days) => chartDays.value = days;
}
