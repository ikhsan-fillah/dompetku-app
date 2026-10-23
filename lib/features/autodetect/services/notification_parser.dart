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

  static const _otp =
      r'\botp\b|kode verifikasi|jangan bagikan|verification code';
  static const _promo = r'promo|diskon|cashback\s+\d|voucher|flash sale';

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

    final amountMatch = _amountPattern
        .allMatches(text)
        .where((m) => !_isBalance(text, m.start))
        .firstOrNull;
    if (amountMatch == null) return null;
    final amount = int.tryParse(
      amountMatch.group(1)!.replaceAll(RegExp(r'[.,]'), ''),
    );
    if (amount == null || amount <= 0) return null;

    final isExpense =
        RegExp(
          r'(bayar|pembayaran|paid|payment (?:to|of|successful)|sent|kirim|keluar|debit|belanja|pembelian|purchase)',
        ).hasMatch(lower) &&
        !RegExp(r'(terima|received|masuk|cashback)').hasMatch(lower);
    final isIncome = RegExp(
      r'(terima|received|masuk|kredit|credited)',
    ).hasMatch(lower);
    if (!isExpense && !isIncome) return null;

    final merchant = _merchant(text);
    return ParsedPayment(
      source: source,
      amount: amount,
      merchant: merchant,
      isExpense: isExpense,
    );
  }

  /// Nominal yang didahului kata saldo/sisa bukan nominal transaksi.
  bool _isBalance(String text, int start) {
    final before = text
        .substring(start < 14 ? 0 : start - 14, start)
        .toLowerCase();
    return before.contains('saldo') || before.contains('sisa');
  }

  String? _sourceName(String appId) => switch (appId) {
    'id.co.bca.mobile' => 'BCA mobile',
    'com.gojek.gopay' || 'com.gojek.app' => 'GoPay',
    'com.shopee.id' => 'ShopeePay',
    'id.dana' => 'DANA',
    'id.co.bri.brimo' => 'BRImo',
    'com.jago.digitalBanking' => 'Jago',
    'ovo.id' => 'OVO',
    'com.telkom.mwallet' => 'LinkAja',
    'id.bmri.livin' => "Livin' by Mandiri",
    'src.com.bni' => 'BNI Mobile',
    'com.bsm.activity2' => 'BSI Mobile',
    'com.bcadigital.blu' => 'blu by BCA',
    'id.co.bankbkemobile.digitalbank' => 'SeaBank',
    'com.btpn.dc' => 'Jenius',
    _ => null,
  };

  /// Nama setelah "ke/at/to", dipotong di kata penghubung berikutnya. Kata
  /// seperti "ke rekening" atau "to your account" bukan nama merchant.
  String? _merchant(String text) {
    final match = RegExp(
      r'\b(?:ke|at|to)\s+(?!rekening\b|akun\b|kartu\b|nomor\b|no\b|account\b|your\b|you\b)([A-Za-z][A-Za-z0-9 .&\-]{2,29})',
      caseSensitive: false,
    ).firstMatch(text);
    final raw = match?.group(1);
    if (raw == null) return null;
    final name = raw
        .split(
          RegExp(
            r'\s+(?:pada|sebesar|senilai|tanggal|dengan|dari|on|for|from)\b',
            caseSensitive: false,
          ),
        )
        .first
        .trim();
    return name.length < 3 ? null : name;
  }
}

/// Kunci unik draft notifikasi: sumber, nominal, dan waktu posting persis.
/// Notifikasi kembar yang diposting berdekatan ditolak lewat
/// `DraftRepository.existsNear` dengan jendela [nearWindow], jadi tidak ada
/// batas bucket yang bisa meloloskan atau menggabungkan notifikasi secara acak.
class DraftDedupe {
  const DraftDedupe._();

  static const nearWindow = Duration(minutes: 2);

  static String keyFor({
    required String source,
    required int amount,
    required DateTime detectedAt,
  }) => 'notif:$source:$amount:${detectedAt.toUtc().millisecondsSinceEpoch}';
}
