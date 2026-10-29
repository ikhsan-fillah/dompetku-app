/// Kelompok broker menurut aturan pengguna (tabel `broker_group`).
///
/// Ini aturan pengguna, bukan fakta pasar: anggota kelompok "bandar" tidak
/// pasti bandar. Hanya dipakai untuk membaca arah net beli atau net jual.
enum BrokerGroup {
  ritel,
  bandar,
  asing;

  /// Nilai kolom `grp`. Null untuk `belum_diklasifikasi` atau nilai asing.
  static BrokerGroup? fromDb(String value) => switch (value) {
    'ritel' => BrokerGroup.ritel,
    'bandar' => BrokerGroup.bandar,
    'asing' => BrokerGroup.asing,
    _ => null,
  };

  /// Kunci terjemahan, juga dipakai sebagai label bawaan.
  String get label => switch (this) {
    BrokerGroup.ritel => 'Ritel',
    BrokerGroup.bandar => 'Bandar',
    BrokerGroup.asing => 'Asing',
  };
}

/// Pemetaan kode broker ke kelompok. Broker yang tidak ada di sini dianggap
/// belum diklasifikasi dan tidak masuk total kelompok mana pun.
class BrokerGroupRules {
  const BrokerGroupRules(this._byCode);

  const BrokerGroupRules.empty() : _byCode = const {};

  final Map<String, BrokerGroup> _byCode;

  bool get isEmpty => _byCode.isEmpty;

  BrokerGroup? groupOf(String brokerCode) => _byCode[brokerCode.toUpperCase()];

  /// Membaca baris tabel `broker_group`; baris dengan `grp` yang tidak dikenal
  /// dilewati.
  factory BrokerGroupRules.fromRows(Iterable<Map<String, dynamic>> rows) {
    final byCode = <String, BrokerGroup>{};
    for (final row in rows) {
      final code = row['broker_code'];
      final group = row['grp'];
      if (code is! String || group is! String) continue;
      final parsed = BrokerGroup.fromDb(group);
      if (parsed != null) byCode[code.toUpperCase()] = parsed;
    }
    return BrokerGroupRules(byCode);
  }
}
