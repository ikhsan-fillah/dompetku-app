import '../models/broker_group.dart';
import '../models/broker_range_row.dart';

/// Total satu kelompok pada satu rentang.
class GroupTotal {
  const GroupTotal({
    this.buyIdr = 0,
    this.sellIdr = 0,
    this.brokerCount = 0,
    this.approxCount = 0,
  });

  /// Jumlah nilai broker yang net beli, lalu net jual (keduanya positif).
  final int buyIdr;
  final int sellIdr;

  /// Jumlah broker kelompok ini yang tampil pada rentang tersebut.
  final int brokerCount;

  /// Berapa dari broker itu yang nilainya dibulatkan di layar sumber.
  final int approxCount;

  int get netIdr => buyIdr - sellIdr;

  bool get hasApprox => approxCount > 0;
}

/// Ringkasan semua kelompok untuk satu rentang.
class GroupSummary {
  const GroupSummary({required this.groups, required this.unclassified});

  final Map<BrokerGroup, GroupTotal> groups;

  /// Broker yang tampil tetapi tidak masuk kelompok mana pun.
  final GroupTotal unclassified;

  GroupTotal of(BrokerGroup group) => groups[group] ?? const GroupTotal();
}

/// Menjumlahkan net beli dan net jual per kelompok. Logika ini sengaja ada di
/// app, bukan di database: aturan kelompok bisa berubah tanpa mengubah data
/// per broker yang tersimpan.
///
/// Batasan: Broker Summary hanya menampilkan broker teratas di tiap sisi, jadi
/// total kelompok adalah total dari broker yang tampil, bukan seluruh pasar.
class BrokerGroupCalculator {
  const BrokerGroupCalculator();

  GroupSummary summarize(
    Iterable<BrokerRangeRow> rows,
    BrokerGroupRules rules,
  ) {
    final buy = <BrokerGroup?, int>{};
    final sell = <BrokerGroup?, int>{};
    final count = <BrokerGroup?, int>{};
    final approx = <BrokerGroup?, int>{};

    for (final row in rows) {
      final group = rules.groupOf(row.brokerCode);
      final sideMap = row.side == BrokerSide.buy ? buy : sell;
      sideMap[group] = (sideMap[group] ?? 0) + row.valueIdr;
      count[group] = (count[group] ?? 0) + 1;
      if (row.isApprox) approx[group] = (approx[group] ?? 0) + 1;
    }

    GroupTotal totalFor(BrokerGroup? group) => GroupTotal(
      buyIdr: buy[group] ?? 0,
      sellIdr: sell[group] ?? 0,
      brokerCount: count[group] ?? 0,
      approxCount: approx[group] ?? 0,
    );

    return GroupSummary(
      groups: {for (final group in BrokerGroup.values) group: totalFor(group)},
      unclassified: totalFor(null),
    );
  }
}
