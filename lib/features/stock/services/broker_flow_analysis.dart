import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import 'broker_group_calculator.dart';

/// Net satu broker di keempat rentang (Latest, 7D, 1M, 3M). Null berarti
/// broker itu tidak tampil di daftar rentang tersebut, bukan nol.
class BrokerTrail {
  const BrokerTrail({
    required this.code,
    required this.group,
    required this.values,
  });

  final String code;
  final BrokerGroup? group;

  /// Satu nilai per [brokerRangeLabels], urut sama.
  final List<int?> values;

  /// Berapa rentang yang arahnya sama dengan [sign] (1 beli, -1 jual).
  int sameAs(int sign) =>
      values.where((v) => v != null && v.sign == sign).length;
}

/// Satu broker dengan nilainya di satu rentang.
class BrokerValue {
  const BrokerValue({
    required this.code,
    required this.group,
    required this.value,
    required this.approx,
  });

  final String code;
  final BrokerGroup? group;
  final int value;
  final bool approx;
}

/// Bahan kalimat pembuka kartu kelompok: kelompok dengan net terbesar di
/// rentang terpilih dan arahnya di rentang pembanding.
class FlowHeadline {
  const FlowHeadline({
    required this.group,
    required this.selectedLabel,
    required this.selectedNet,
    required this.compareLabel,
    required this.compareNet,
    required this.compareApprox,
  });

  final BrokerGroup group;
  final String selectedLabel;
  final int selectedNet;
  final String compareLabel;
  final int compareNet;
  final bool compareApprox;

  bool get reversed =>
      compareNet != 0 &&
      selectedNet != 0 &&
      compareNet.sign != selectedNet.sign;
}

/// Analisis aliran dana lintas rentang. Semuanya aturan deskriptif dari data
/// broker yang tampil di Stockbit, bukan model ML dan bukan sinyal.
class BrokerFlowAnalysis {
  BrokerFlowAnalysis(
    List<BrokerRangeRow> rows,
    this.rules, {
    List<BrokerRangeRow> foreignRows = const [],
    BrokerGroupCalculator calculator = const BrokerGroupCalculator(),
  }) {
    for (final label in brokerRangeLabels) {
      final inRange = [
        for (final row in rows)
          if (row.rangeLabel == label) row,
      ];
      if (inRange.isEmpty) continue;
      _rows[label] = inRange;
      summaries[label] = calculator.summarize(
        inRange,
        rules,
        foreignRows: [
          for (final row in foreignRows)
            if (row.rangeLabel == label) row,
        ],
      );
      final net = <String, int>{};
      final approx = <String, bool>{};
      for (final row in inRange) {
        net[row.brokerCode] = (net[row.brokerCode] ?? 0) + row.signedValueIdr;
        approx[row.brokerCode] =
            (approx[row.brokerCode] ?? false) || row.isApprox;
      }
      _net[label] = net;
      _approx[label] = approx;
    }
  }

  final BrokerGroupRules rules;

  /// Ringkasan kelompok per rentang yang punya data.
  final summaries = <String, GroupSummary>{};

  final _rows = <String, List<BrokerRangeRow>>{};
  final _net = <String, Map<String, int>>{};
  final _approx = <String, Map<String, bool>>{};

  bool get hasAllRanges =>
      brokerRangeLabels.every((label) => summaries.containsKey(label));

  /// Rentang lain selain [selected] yang punya data, urut standar.
  List<String> otherLabels(String selected) => [
    for (final label in brokerRangeLabels)
      if (label != selected && summaries.containsKey(label)) label,
  ];

  /// Rentang pembanding untuk kalimat pembuka: 1M, atau 3M bila yang
  /// dipilih sudah 1M.
  String? compareLabelFor(String selected) {
    final preferred = selected == '1M' ? '3M' : '1M';
    if (summaries.containsKey(preferred)) return preferred;
    final others = otherLabels(selected);
    return others.isEmpty ? null : others.last;
  }

  FlowHeadline? headline(String selected) {
    final summary = summaries[selected];
    final compare = compareLabelFor(selected);
    if (summary == null || compare == null) return null;
    BrokerGroup? best;
    for (final group in BrokerGroup.values) {
      final net = summary.of(group).netIdr;
      if (net == 0) continue;
      if (best == null || net.abs() > summary.of(best).netIdr.abs()) {
        best = group;
      }
    }
    if (best == null) return null;
    final other = summaries[compare]!.of(best);
    return FlowHeadline(
      group: best,
      selectedLabel: selected,
      selectedNet: summary.of(best).netIdr,
      compareLabel: compare,
      compareNet: other.netIdr,
      compareApprox: other.hasApprox,
    );
  }

  BrokerTrail trailOf(String code) => BrokerTrail(
    code: code,
    group: rules.groupOf(code),
    values: [for (final label in brokerRangeLabels) _net[label]?[code]],
  );

  /// Broker yang tampil di keempat rentang dengan arah sama ([sign] 1 beli,
  /// -1 jual), terbesar di 3M dulu. Kosong bila ada rentang tanpa data.
  List<BrokerTrail> consistent(int sign) {
    if (!hasAllRanges) return const [];
    final codes = _net[brokerRangeLabels.first]!.keys;
    final out = [
      for (final code in codes)
        if (trailOf(code).sameAs(sign) == brokerRangeLabels.length)
          trailOf(code),
    ];
    out.sort((a, b) => b.values.last!.abs().compareTo(a.values.last!.abs()));
    return out;
  }

  /// Porsi [k] broker teratas terhadap total sisi [side] di [label], 0 sampai 1.
  double? topShare(String label, BrokerSide side, {int k = 3}) {
    final values = [
      for (final row in _rows[label] ?? const <BrokerRangeRow>[])
        if (row.side == side) row.valueIdr,
    ]..sort((a, b) => b.compareTo(a));
    if (values.length <= k) return null;
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return null;
    final top = values.take(k).fold<int>(0, (a, b) => a + b);
    return top / total;
  }

  /// [k] broker dengan nilai terbesar di sisi [side] pada [label].
  List<BrokerValue> largest(String label, BrokerSide side, {int k = 3}) {
    final rows = [
      for (final row in _rows[label] ?? const <BrokerRangeRow>[])
        if (row.side == side) row,
    ]..sort((a, b) => b.valueIdr.compareTo(a.valueIdr));
    return [
      for (final row in rows.take(k))
        BrokerValue(
          code: row.brokerCode,
          group: rules.groupOf(row.brokerCode),
          value: row.signedValueIdr,
          approx: row.isApprox,
        ),
    ];
  }

  /// Net broker [code] di [label], null bila tidak tampil.
  int? netOf(String label, String code) => _net[label]?[code];

  bool approxOf(String label, String code) => _approx[label]?[code] ?? false;
}
