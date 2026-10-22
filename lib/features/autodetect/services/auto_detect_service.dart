import 'dart:async';

import 'package:flutter/services.dart';

import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../../drafts/models/draft_model.dart';
import '../../drafts/repositories/draft_repository.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
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
    TransactionRepository? transactions,
    CategoryRepository? categories,
  }) : _transactions = transactions,
       _categories = categories,
       _parser = parser ?? const NotificationParser(),
       _settings = settings ?? AutoDetectSettings();

  static const _events = EventChannel('tally/payment_notifications');
  static const _access = MethodChannel('tally/notification_access');

  final DraftRepository _drafts;
  final TransactionRepository? _transactions;
  final CategoryRepository? _categories;
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

  /// Mode simpan otomatis: draft yang baru masuk langsung dicatat sebagai
  /// transaksi di kategori "Other" (bawaan) sesuai jenisnya. Bila kategori itu
  /// tidak ada, draft dibiarkan menunggu di Draf.
  Future<void> _saveDraft(String dedupeKey) async {
    final transactions = _transactions;
    final categories = _categories;
    if (transactions == null || categories == null) return;
    try {
      final pending = await _drafts.getPending();
      final draft = pending.where((d) => d.dedupeKey == dedupeKey).firstOrNull;
      final id = draft?.id;
      if (draft == null || id == null) return;
      final category = _fallbackCategory(await categories.getAll(), draft.kind);
      final categoryId = category?.id;
      if (categoryId == null) return;
      final now = DateTime.now();
      final merchant = draft.merchant?.trim();
      await transactions.insert(
        TransactionModel(
          type: draft.kind,
          title: (merchant == null || merchant.isEmpty)
              ? draft.source
              : merchant,
          amount: draft.amount,
          transactionDate: draft.detectedAt.toLocal(),
          categoryId: categoryId,
          merchantOrSource: merchant ?? draft.source,
          note: 'Dicatat otomatis dari notifikasi ${draft.source}',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _drafts.setStatus(id, DraftStatus.confirmed);
    } catch (_) {
      // Gagal menyimpan otomatis: draft tetap pending dan bisa dikonfirmasi manual.
    }
  }

  CategoryModel? _fallbackCategory(
    List<CategoryModel> all,
    TransactionType kind,
  ) {
    final active = all.where((c) => c.type == kind && !c.isArchived);
    return active.where((c) => c.isDefault && c.name == 'Other').firstOrNull ??
        active.firstOrNull;
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
    if (await _drafts.existsNear(
      source: parsed.source,
      amount: parsed.amount,
      at: detectedAt,
      window: DraftDedupe.nearWindow,
    )) {
      return;
    }
    final dedupeKey = DraftDedupe.keyFor(
      source: parsed.source,
      amount: parsed.amount,
      detectedAt: detectedAt,
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
        dedupeKey: dedupeKey,
      ),
    );
    if (await _settings.getSaveAuto()) await _saveDraft(dedupeKey);
    if (Get.isRegistered<DataRefreshService>()) {
      Get.find<DataRefreshService>().bump();
    }
  }
}
