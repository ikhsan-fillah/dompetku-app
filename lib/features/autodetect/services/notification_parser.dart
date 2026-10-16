/// Hasil parse satu notifikasi pembayaran. Teks mentah tidak pernah disimpan.
class ParsedPayment {
  const ParsedPayment({
    required this.source,
    required this.amount,
    this.merchant,
    required this.isExpense,
  });

  final String source;
  final int amount;
  final String? merchant;
  final bool isExpense;
}

/// Parser regex per app. Mengembalikan null untuk OTP, promo, atau teks tak dikenal.
class NotificationParser {
  const NotificationParser();

  static const _otp = r'\botp\b|kode verifikasi|jangan bagikan|verification code';
  static const _promo = r'promo|diskon|cashback\s+\d|voucher|diskon|flash sale';

  static final _amountPattern = RegExp(
    r'(?:Rp\.?\s?)([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]+)',
    caseSensitive: false,
  );

  ParsedPayment? parse(String appId, String text) {
    final lower = text.toLowerCase();
    if (RegExp(_otp).hasMatch(lower)) return null;
    if (RegExp(_promo).hasMatch(lower)) return null;

    final source = _sourceName(appId);
    if (source == null) return null;

    final amountMatch = _amountPattern.firstMatch(text);
    if (amountMatch == null) return null;
    final amount = int.tryParse(
      amountMatch.group(1)!.replaceAll(RegExp(r'[.,]'), ''),
    );
    if (amount == null || amount <= 0) return null;

    final isExpense = RegExp(r'(bayar|pembayaran|transaksi|paid|payment|sent|kirim)')
            .hasMatch(lower) &&
        !RegExp(r'(terima|received|masuk|cashback)').hasMatch(lower);
    final isIncome = RegExp(r'(terima|received|masuk)').hasMatch(lower);
    if (!isExpense && !isIncome) return null;

    final merchant = _merchant(text);
    return ParsedPayment(
      source: source,
      amount: amount,
      merchant: merchant,
      isExpense: isExpense,
    );
  }

  String? _sourceName(String appId) => switch (appId) {
    'id.co.bca.mobile' => 'BCA mobile',
    'com.gojek.gopay' || 'com.gojek.app' => 'GoPay',
    'com.shopee.id' => 'ShopeePay',
    'id.dana' => 'DANA',
    _ => null,
  };

  String? _merchant(String text) {
    final match = RegExp(r'(?:ke|at|to)\s+([A-Za-z0-9 .&\-]{3,30})').firstMatch(text);
    return match?.group(1)?.trim();
  }
}

/// Kunci dedupe: sumber, nominal, dan waktu dibulatkan ke jendela (menit).
class DraftDedupe {
  const DraftDedupe._();

  static String keyFor({
    required String source,
    required int amount,
    required DateTime detectedAt,
    int windowMinutes = 5,
  }) {
    final minutes = detectedAt.toUtc().millisecondsSinceEpoch ~/ 60000;
    final bucket = minutes ~/ windowMinutes;
    return 'notif:$source:$amount:$bucket';
  }
}
