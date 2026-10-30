enum BrokerSide { buy, sell }

/// Rentang yang dibaca dari Broker Summary, urut dari yang terpendek.
const brokerRangeLabels = ['Latest', '7D', '1M', '3M'];

/// Net beli atau net jual satu broker untuk satu rentang tanggal
/// (tabel `broker_range_snapshot`). Satu broker muncul di satu sisi saja
/// karena Broker Summary dibaca dengan Net aktif.
class BrokerRangeRow {
  const BrokerRangeRow({
    required this.ticker,
    required this.rangeLabel,
    required this.rangeStart,
    required this.rangeEnd,
    required this.brokerCode,
    required this.side,
    required this.valueIdr,
    this.isApprox = false,
  });

  final String ticker;
  final String rangeLabel;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String brokerCode;
  final BrokerSide side;

  /// Nilai mutlak dalam rupiah (tanpa tanda).
  final int valueIdr;

  /// True bila nilainya dibulatkan di layar sumber (mis. 2,2T).
  final bool isApprox;

  /// Positif untuk net beli, negatif untuk net jual.
  int get signedValueIdr => side == BrokerSide.buy ? valueIdr : -valueIdr;

  /// Kolom wajib dicocokkan dengan pola map; baris yang bentuknya salah
  /// langsung gagal. `value_is_approx` opsional (bawaan false).
  factory BrokerRangeRow.fromMap(Map<String, dynamic> map) => switch (map) {
    {
      'ticker': final String ticker,
      'range_label': final String rangeLabel,
      'range_start': final String rangeStart,
      'range_end': final String rangeEnd,
      'broker_code': final String brokerCode,
      'side': final String side,
      'value_idr': final num valueIdr,
    } =>
      BrokerRangeRow(
        ticker: ticker,
        rangeLabel: rangeLabel,
        rangeStart: DateTime.parse(rangeStart),
        rangeEnd: DateTime.parse(rangeEnd),
        brokerCode: brokerCode,
        side: side == 'sell' ? BrokerSide.sell : BrokerSide.buy,
        valueIdr: valueIdr.toInt(),
        isApprox: map['value_is_approx'] as bool? ?? false,
      ),
    _ => throw FormatException('Baris broker tidak valid: $map'),
  };
}

/// Dari semua baris satu saham, ambil hanya snapshot terbaru untuk tiap label
/// rentang (rentang dengan `range_end` paling baru).
List<BrokerRangeRow> latestSnapshotPerRange(List<BrokerRangeRow> rows) {
  final newestEnd = <String, DateTime>{};
  for (final row in rows) {
    final current = newestEnd[row.rangeLabel];
    if (current == null || row.rangeEnd.isAfter(current)) {
      newestEnd[row.rangeLabel] = row.rangeEnd;
    }
  }
  return [
    for (final row in rows)
      if (row.rangeEnd == newestEnd[row.rangeLabel]) row,
  ];
}
