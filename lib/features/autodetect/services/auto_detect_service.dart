import 'dart:async';

import 'package:flutter/services.dart';

import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../drafts/models/draft_model.dart';
import '../../drafts/repositories/draft_repository.dart';
import 'auto_detect_settings.dart';
import 'notification_parser.dart';

/// Menghubungkan event notifikasi native ke parser dan draft. Teks mentah
/// tidak pernah disimpan di Dart; di sisi native hanya ditahan sementara
/// bila app tertutup dan dihapus saat diambil. Hanya app yang dipilih user yang diproses.
class AutoDetectService {
  AutoDetectService(
    this._drafts, {
    NotificationParser? parser,
    AutoDetectSettings? settings,
  }) : _parser = parser ?? const NotificationParser(),
       _settings = settings ?? AutoDetectSettings();

  static const _events = EventChannel('tally/payment_notifications');
  static const _access = MethodChannel('tally/notification_access');

  final DraftRepository _drafts;
  final NotificationParser _parser;
  final AutoDetectSettings _settings;

  StreamSubscription<dynamic>? _listener;

  Future<bool> isAccessEnabled() async {
    try {
      return (await _access.invokeMethod<bool>('isEnabled')) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAccessSettings() => _access.invokeMethod('openSettings');

  Future<void> openAppDetails() => _access.invokeMethod('openAppDetails');

  void start() {
    if (_listener != null) return;
    _listener = _events.receiveBroadcastStream().listen(_onEvent);
    unawaited(drainPending());
  }

  /// Memproses notifikasi yang masuk saat app tertutup.
  Future<void> drainPending() async {
    try {
      final pending = await _access.invokeMethod<List<dynamic>>('drainPending');
      for (final event in pending ?? const <dynamic>[]) {
        await _onEvent(event);
      }
    } on PlatformException {
      return;
    }
  }

  Future<void> _onEvent(dynamic event) async {
    if (event is! Map) return;
    final packageName = event['package'] as String?;
    final text = event['text'] as String?;
    final postTime = event['postTime'] as int?;
    if (packageName == null || text == null || postTime == null) return;

    if (!(await _settings.getApps()).contains(packageName)) return;

    final parsed = _parser.parse(packageName, text);
    if (parsed == null) return;

    final detectedAt = DateTime.fromMillisecondsSinceEpoch(
      postTime,
      isUtc: true,
    );
    await _drafts.insertIfNew(
      DraftModel(
        source: parsed.source,
        kind: parsed.isExpense
            ? TransactionType.expense
            : TransactionType.income,
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
    if (Get.isRegistered<DataRefreshService>()) {
      Get.find<DataRefreshService>().bump();
    }
  }
}
