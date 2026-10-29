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

  factory WatchlistItem.fromMap(Map<String, dynamic> map) => WatchlistItem(
    ticker: map['ticker'] as String,
    isActive: map['is_active'] as bool? ?? true,
    note: map['note'] as String?,
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
  );

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
