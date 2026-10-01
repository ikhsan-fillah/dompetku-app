/// Hasil penguraian teks struk. Semua field bisa kosong bila tidak terbaca.
class ParsedReceipt {
  const ParsedReceipt({this.merchant, this.date, this.total});

  final String? merchant;
  final DateTime? date;
  final int? total;

  bool get isComplete => merchant != null && date != null && total != null;
}

/// Mengurai teks mentah hasil OCR menjadi merchant, tanggal, dan total.
/// Murni (tanpa plugin) agar mudah diuji. Hasilnya hanya usulan untuk layar review.
class ReceiptParser {
  const ReceiptParser();

  static const _months = <String, int>{
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'mei': 5,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'agu': 8,
    'ags': 8,
    'aug': 8,
    'sep': 9,
    'okt': 10,
    'oct': 10,
    'nov': 11,
    'des': 12,
    'dec': 12,
  };

  static const _merchantNoise = <String>[
    'npwp',
    'telp',
    'tel.',
    'jl.',
    'jalan',
    'struk',
    'faktur',
    'invoice',
    'kasir',
    'www.',
    'http',
  ];

  static const _totalExcluded = <String>[
    'kembali',
    'change',
    'tunai',
    'cash',
    'item',
    'qty',
    'diskon',
    'discount',
    'hemat',
  ];

  static const _strongTotals = <String>[
    'grand total',
    'total bayar',
    'total belanja',
    'total tagihan',
    'total pembayaran',
    'jumlah bayar',
    'total akhir',
    'amount due',
  ];

  static final _isoDate = RegExp(r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b');
  static final _numericDate =
      RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})\b');
  static final _namedDate = RegExp(
    r'\b(\d{1,2})\s+(jan|feb|mar|apr|mei|may|jun|jul|agu|ags|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s+(\d{4})\b',
    caseSensitive: false,
  );
  static final _amountToken = RegExp(r'\d[\d.,]*\d|\d');
  static final _letter = RegExp(r'[A-Za-z]');

  ParsedReceipt parse(String raw) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return ParsedReceipt(
      merchant: _merchant(lines),
      date: _date(lines),
      total: _total(lines),
    );
  }

  /// Mengubah token angka seperti "25.000", "25.000,00", atau "25,000" menjadi rupiah.
  static int? parseAmountToken(String token) {
    final withoutDecimals = token.replaceFirst(RegExp(r'[.,]\d{1,2}$'), '');
    final digits = withoutDecimals.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  String? _merchant(List<String> lines) {
    for (final line in lines.take(5)) {
      final lower = line.toLowerCase();
      if (_merchantNoise.any((word) => lower.contains(word))) continue;
      final letters = _letter.allMatches(line).length;
      if (letters < 3) continue;
      if (letters / line.length < 0.5) continue;
      return line;
    }
    return null;
  }

  DateTime? _date(List<String> lines) {
    for (final line in lines) {
      for (final match in _isoDate.allMatches(line)) {
        final date = _buildDate(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
        if (date != null) return date;
      }
      for (final match in _numericDate.allMatches(line)) {
        var year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;
        final date = _buildDate(
          year,
          int.parse(match.group(2)!),
          int.parse(match.group(1)!),
        );
        if (date != null) return date;
      }
      for (final match in _namedDate.allMatches(line)) {
        final month = _months[match.group(2)!.toLowerCase()];
        if (month == null) continue;
        final date = _buildDate(
          int.parse(match.group(3)!),
          month,
          int.parse(match.group(1)!),
        );
        if (date != null) return date;
      }
    }
    return null;
  }

  DateTime? _buildDate(int year, int month, int day) {
    if (year < 2000) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  int? _total(List<String> lines) {
    int? best;
    var bestPriority = 0;
    for (var i = 0; i < lines.length; i++) {
      final priority = _totalPriority(lines[i].toLowerCase());
      if (priority == 0 || priority < bestPriority) continue;
      final amount = _amountOnLine(lines[i]) ??
          (i + 1 < lines.length ? _amountOnlyLine(lines[i + 1]) : null);
      if (amount == null) continue;
      best = amount;
      bestPriority = priority;
    }
    return best;
  }

  int _totalPriority(String lower) {
    if (_totalExcluded.any((word) => lower.contains(word))) return 0;
    if (_strongTotals.any((word) => lower.contains(word))) return 3;
    final withoutSubtotal = lower.replaceAll(RegExp(r'sub\s*-?\s*total'), '');
    return withoutSubtotal.contains('total') ? 2 : 0;
  }

  int? _amountOnLine(String line) {
    int? last;
    for (final match in _amountToken.allMatches(line)) {
      final amount = parseAmountToken(match.group(0)!);
      if (amount != null && amount >= 100) last = amount;
    }
    return last;
  }

  int? _amountOnlyLine(String line) {
    final stripped = line.replaceAll(RegExp(r'rp\.?', caseSensitive: false), '');
    if (_letter.hasMatch(stripped)) return null;
    return _amountOnLine(line);
  }
}
