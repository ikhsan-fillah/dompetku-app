import 'package:flutter/painting.dart';

/// Warna tiap bulan di halaman Rekap (kartu cerita dan kartu bulan).
///
/// Diacak dari tahun dan bulan sehingga selalu sama setiap kali dibuka, dan
/// tidak pernah sama dengan bulan sebelumnya maupun bulan yang sama tahun
/// lalu. Bulan berikutnya ikut aturan yang sama, jadi tetangga selalu beda.
abstract final class MonthPalette {
  /// 14 warna yang cukup gelap untuk teks putih dan serasi dengan kertas.
  static const colors = <Color>[
    Color(0xFFC4892A), // kunyit
    Color(0xFF3F7A9E), // laut
    Color(0xFFB5663E), // terakota
    Color(0xFF2E6B3C), // hutan
    Color(0xFF7A4E7E), // plum
    Color(0xFF4E6A8F), // batu
    Color(0xFF6F8A2E), // zaitun
    Color(0xFFB2556A), // mawar
    Color(0xFF0E5E55), // teal
    Color(0xFF8A6A1F), // karamel
    Color(0xFF3D4F8C), // nila
    Color(0xFFC9743A), // jingga
    Color(0xFF5B7B6A), // lumut
    Color(0xFF8A5A3B), // cokelat
  ];

  /// Rantai warna dihitung berurutan sejak bulan ini supaya aturan
  /// "beda dari tetangga dan tahun lalu" konsisten di mana pun dibaca.
  static const _epochYear = 2000;

  static final _cache = <int, int>{};

  static Color of(int year, int month) => colors[_index(year, month)];

  static int _key(int year, int month) => year * 12 + (month - 1);

  static int _index(int year, int month) {
    final key = _key(year, month);
    final cached = _cache[key];
    if (cached != null) return cached;
    final startYear = year < _epochYear ? year : _epochYear;
    var y = startYear;
    var m = 1;
    while (true) {
      final k = _key(y, m);
      if (!_cache.containsKey(k)) {
        final prev = _cache[k - 1];
        final lastYear = _cache[k - 12];
        var idx = _seed(y, m) % colors.length;
        while (idx == prev || idx == lastYear) {
          idx = (idx + 1) % colors.length;
        }
        _cache[k] = idx;
      }
      if (k == key) return _cache[k]!;
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
  }

  static int _seed(int year, int month) =>
      ((year * 31 + month * 17) * 2654435761) % 4294967296;
}
