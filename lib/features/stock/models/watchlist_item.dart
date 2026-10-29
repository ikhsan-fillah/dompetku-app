/// Satu saham di watchlist (tabel `watchlist`). Saham nonaktif tidak dianalisis
/// lagi, tetapi riwayat datanya tetap tersimpan.
class WatchlistItem {
  const WatchlistItem({
    required this.ticker,
    required this.isActive,
    this.note,
    this.createdAt,
  });

  final String ticker;
  final bool isActive;
  final String? note;
  final DateTime? createdAt;

  /// Kolom wajib dicocokkan dengan pola map; baris yang bentuknya salah
  /// langsung gagal supaya data rusak tidak diam-diam hilang. `note` dan
  /// `created_at` opsional, jadi dibaca dari map langsung.
  factory WatchlistItem.fromMap(Map<String, dynamic> map) => switch (map) {
    {'ticker': final String ticker, 'is_active': final bool isActive} =>
      WatchlistItem(
        ticker: ticker,
        isActive: isActive,
        note: map['note'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
      ),
    _ => throw FormatException('Baris watchlist tidak valid: $map'),
  };

  WatchlistItem copyWith({bool? isActive}) => WatchlistItem(
    ticker: ticker,
    isActive: isActive ?? this.isActive,
    note: note,
    createdAt: createdAt,
  );
}

/// Kode saham BEI: empat huruf kapital. Mengembalikan null bila tidak valid.
String? normalizeTicker(String raw) {
  final value = raw.trim().toUpperCase();
  return RegExp(r'^[A-Z]{4}$').hasMatch(value) ? value : null;
}
