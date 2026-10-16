import 'package:flutter/services.dart';

import '../../../core/constant/domain_enums.dart';
import '../../drafts/models/draft_model.dart';
import '../../drafts/repositories/draft_repository.dart';
import 'notification_parser.dart';

/// Menghubungkan event notifikasi native ke parser dan draft. Teks mentah
/// tidak pernah disimpan: hanya hasil parse yang masuk database.
class AutoDetectService {
  AutoDetectService(this._drafts, {NotificationParser? parser})
    : _parser = parser ?? const NotificationParser();

  static const _events = EventChannel('tally/payment_notifications');
  static const _access = MethodChannel('tally/notification_access');

  final DraftRepository _drafts;
  final NotificationParser _parser;

  Stream<dynamic>? _subscription;

  Future<bool> isAccessEnabled() async {
    try {
      return (await _access.invokeMethod<bool>('isEnabled')) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAccessSettings() => _access.invokeMethod('openSettings');

  void start() {
    _subscription ??= _events.receiveBroadcastStream();
    _subscription!.listen((event) => _onEvent(event));
  }

  Future<void> _onEvent(dynamic event) async {
    if (event is! Map) return;
    final packageName = event['package'] as String?;
    final text = event['text'] as String?;
    final postTime = event['postTime'] as int?;
    if (packageName == null || text == null || postTime == null) return;

    final parsed = _parser.parse(packageName, text);
    if (parsed == null || !parsed.isExpense) return;

    final detectedAt = DateTime.fromMillisecondsSinceEpoch(postTime, isUtc: true);
    await _drafts.insertIfNew(
      DraftModel(
        source: parsed.source,
        kind: TransactionType.expense,
        amount: parsed.amount,
        merchant: parsed.merchant,
        detectedAt: detectedAt,
        dedupeKey: DraftDedupe.keyFor(
          source: parsed.source,
          amount: parsed.amount,
          detectedAt: detectedAt,
        ),
      ),
    );
  }
}
