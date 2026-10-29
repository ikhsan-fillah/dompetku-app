import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../data/stock_repository.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../services/broker_group_calculator.dart';

/// Data satu saham: baris per broker dan aturan kelompok.
class StockDetailData {
  const StockDetailData({required this.rows, required this.rules});

  final List<BrokerRangeRow> rows;
  final BrokerGroupRules rules;
}

/// Tampilan per broker satu saham, dengan total kelompok yang dihitung di app.
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
  final range = brokerRangeLabels.first.obs;

  StockDetailData? get data => state.value.data;

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

  Future<void> load() async {
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

  void selectRange(String label) => range.value = label;
}
