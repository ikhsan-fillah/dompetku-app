/// Aturan input nominal rupiah dari keypad. Nominal disimpan sebagai deretan digit.
abstract final class AmountInput {
  static const maxDigits = 12;

  /// Menerapkan satu tombol keypad (0-9, 000, atau ⌫) pada [current].
  static String apply(String current, String key) {
    if (key == '⌫') {
      return current.isEmpty
          ? current
          : current.substring(0, current.length - 1);
    }
    if (!RegExp(r'^\d+$').hasMatch(key)) return current;
    final next = (current + key).replaceFirst(RegExp(r'^0+'), '');
    if (next.length > maxDigits) return current;
    return next;
  }

  static int? parse(String digits) =>
      digits.isEmpty ? null : int.tryParse(digits);

  /// Tampilan bertitik ribuan, misalnya 1250000 menjadi 1.250.000.
  static String display(String digits) {
    if (digits.isEmpty) return '0';
    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}
