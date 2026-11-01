/// Skor kata berita pasar satu hari dari tabel `market_news` (judul berita
/// diberi skor -1 sampai 1 dengan daftar kata, bukan model bahasa).
class NewsScore {
  const NewsScore({
    required this.day,
    required this.average,
    required this.titles,
    required this.scored,
  });

  /// Hari terbit (WIB).
  final DateTime day;

  /// Rata-rata skor judul yang punya skor.
  final double average;

  /// Semua judul hari itu, termasuk yang tanpa kata bermuatan.
  final int titles;

  /// Judul yang punya skor.
  final int scored;

  /// Null bila tidak ada judul yang punya skor.
  static NewsScore? fromSentiments(DateTime day, List<Object?> raw) {
    final values = <double>[
      for (final x in raw)
        if (x is num) x.toDouble() else if (x is String) ?double.tryParse(x),
    ];
    if (values.isEmpty) return null;
    return NewsScore(
      day: day,
      average: values.reduce((a, b) => a + b) / values.length,
      titles: raw.length,
      scored: values.length,
    );
  }
}
