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

/// Berapa broker teratas di tiap sisi yang dihitung sebagai Bandar.
const bandarTopCount = 5;

/// Menjumlahkan net beli dan net jual per kelompok. Logika ini sengaja ada di
/// app, bukan di database: aturan kelompok bisa berubah tanpa mengubah data
/// per broker yang tersimpan.
///
/// Aturan:
/// - Ritel: semua broker berlabel ritel yang tampil (top 10 per sisi).
/// - Bandar (label `big_player`): hanya yang masuk [bandarTopCount] teratas di
///   sisinya pada rentang itu, peringkat dari nilai kotor semua broker di
///   sisi tersebut. Broker big player di peringkat bawah tidak dihitung dan
///   tidak masuk "belum diklasifikasi".
/// - Asing: bukan label broker. Dijumlahkan semua dari [foreignRows]
///   (Foreign broker summary), tanpa batas peringkat.
///
/// Batasan: Broker Summary hanya menampilkan broker teratas di tiap sisi, jadi
/// total kelompok adalah total dari broker yang tampil, bukan seluruh pasar.
class BrokerGroupCalculator {
  const BrokerGroupCalculator();

  GroupSummary summarize(
    Iterable<BrokerRangeRow> rows,
    BrokerGroupRules rules, {
    Iterable<BrokerRangeRow> foreignRows = const [],
  }) {
    final all = rows.toList();
    final buy = <BrokerGroup?, int>{};
    final sell = <BrokerGroup?, int>{};
    final count = <BrokerGroup?, int>{};
    final approx = <BrokerGroup?, int>{};

    void add(BrokerGroup? group, BrokerRangeRow row) {
      final sideMap = row.side == BrokerSide.buy ? buy : sell;
      sideMap[group] = (sideMap[group] ?? 0) + row.valueIdr;
      count[group] = (count[group] ?? 0) + 1;
      if (row.isApprox) approx[group] = (approx[group] ?? 0) + 1;
    }

    final topBandar = _topBrokers(all, rules);
    for (final row in all) {
      final group = rules.groupOf(row.brokerCode);
      if (group == BrokerGroup.asing) {
        // Asing bukan label broker; baris ini dianggap belum diklasifikasi.
        add(null, row);
      } else if (group == BrokerGroup.bandar) {
        if (topBandar.contains(row)) add(BrokerGroup.bandar, row);
      } else {
        add(group, row);
      }
    }
    for (final row in foreignRows) {
      add(BrokerGroup.asing, row);
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

  /// Baris Bandar yang masuk [bandarTopCount] teratas di sisi dan rentangnya.
  Set<BrokerRangeRow> _topBrokers(
    List<BrokerRangeRow> rows,
    BrokerGroupRules rules,
  ) {
    final bySlot = <(String, BrokerSide), List<BrokerRangeRow>>{};
    for (final row in rows) {
      bySlot.putIfAbsent((row.rangeLabel, row.side), () => []).add(row);
    }
    final top = <BrokerRangeRow>{};
    for (final slot in bySlot.values) {
      slot.sort((a, b) => b.valueIdr.compareTo(a.valueIdr));
      for (final row in slot.take(bandarTopCount)) {
        if (rules.groupOf(row.brokerCode) == BrokerGroup.bandar) top.add(row);
      }
    }
    return top;
  }
}
