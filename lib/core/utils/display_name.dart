/// Aturan nama tampilan pengguna. Bila belum diisi, sapaan memakai "Friend".
abstract final class DisplayName {
  static const fallback = 'Friend';
  static const maxLength = 24;

  static String greeting(String? raw) {
    final value = (raw ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  static String normalize(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.length <= maxLength) return collapsed;
    return collapsed.substring(0, maxLength).trimRight();
  }

  static String initial(String? raw) {
    final name = greeting(raw);
    return String.fromCharCode(name.runes.first).toUpperCase();
  }
}
