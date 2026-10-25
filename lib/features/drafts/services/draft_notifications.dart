import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/formatter.dart';
import '../../category/repositories/category_repository.dart';
import '../../recurring/services/recurring_reminders.dart';
import '../models/draft_model.dart';
import '../repositories/draft_repository.dart';

/// Tombol di notifikasi draf.
enum DraftNoticeAction { confirm, view, pickCategory }

/// Isi notifikasi draf yang akan ditampilkan.
class DraftNotice {
  const DraftNotice({
    required this.title,
    required this.body,
    required this.count,
    required this.actions,
    required this.payload,
  });

  final String title;
  final String body;

  /// Jumlah draf menunggu; dipakai sebagai angka di ikon app.
  final int count;
  final List<DraftNoticeAction> actions;
  final String payload;
}

/// Format payload notifikasi draf dan cara membacanya.
abstract final class DraftPayload {
  static const all = 'drafts';
  static const _prefix = 'draft:';

  static String one(int id) => '$_prefix$id';

  static bool isDraft(String? payload) =>
      payload == all || (payload?.startsWith(_prefix) ?? false);

  static int? id(String? payload) =>
      payload != null && payload.startsWith(_prefix)
      ? int.tryParse(payload.substring(_prefix.length))
      : null;
}

/// Menyusun notifikasi dari draf yang menunggu. Tanpa I/O.
///
/// Satu draf: sumber dan nominal di judul, tombol Konfirmasi (bila sudah
/// berkategori) atau Pilih kategori. Beberapa draf: digabung jadi satu.
class DraftNoticePlanner {
  const DraftNoticePlanner();

  static const _listed = 3;

  DraftNotice? plan(List<DraftModel> pending, Map<int, String> categoryNames) {
    if (pending.isEmpty) return null;
    if (pending.length == 1) {
      final draft = pending.single;
      final id = draft.id;
      final categoryName = draft.categoryId == null
          ? null
          : categoryNames[draft.categoryId];
      final merchant = draft.merchant?.trim();
      final details = [
        if (merchant != null && merchant.isNotEmpty) merchant,
        if (categoryName != null)
          'kategori @name'.trParams({'name': categoryName}),
      ].join(' · ');
      final hasCategory = draft.categoryId != null;
      return DraftNotice(
        title: 'Draf baru · @source @amount'.trParams({
          'source': draft.source,
          'amount': _signed(draft),
        }),
        body: [
          if (details.isNotEmpty) '$details.',
          hasCategory
              ? 'Konfirmasi untuk mencatat.'.tr
              : 'Pilih kategori dulu sebelum dicatat.'.tr,
        ].join(' '),
        count: 1,
        actions: hasCategory
            ? const [DraftNoticeAction.confirm, DraftNoticeAction.view]
            : const [DraftNoticeAction.pickCategory],
        payload: id == null ? DraftPayload.all : DraftPayload.one(id),
      );
    }
    final listed = [
      for (final draft in pending.take(_listed))
        '${draft.source} ${_signed(draft, plain: true)}',
    ];
    final more = pending.length - _listed;
    return DraftNotice(
      title: '@count draf menunggu konfirmasi'.trParams({
        'count': '${pending.length}',
      }),
      body: [
        listed.join(' · '),
        if (more > 0) '+@count lainnya'.trParams({'count': '$more'}),
      ].join(' · '),
      count: pending.length,
      actions: const [DraftNoticeAction.view],
      payload: DraftPayload.all,
    );
  }

  static String _signed(DraftModel draft, {bool plain = false}) {
    final sign = draft.kind == TransactionType.income ? '+' : '−';
    final amount = plain
        ? formatIdrPlain(draft.amount)
        : formatIdr(draft.amount);
    return '$sign $amount';
  }
}

/// Lapisan notifikasi, dipisah supaya layanan bisa dites tanpa plugin.
abstract interface class DraftNotifier {
  Future<void> show(DraftNotice notice, {required bool alert});
  Future<void> cancel();
}

/// Satu notifikasi draf yang diperbarui (tidak menumpuk). [DraftNotice.count]
/// dikirim sebagai angka notifikasi; peluncur yang mendukung menampilkannya
/// sebagai angka di ikon app, yang lain sebagai titik.
class LocalDraftNotifier implements DraftNotifier {
  LocalDraftNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const id = 800000;
  static const confirmAction = 'draf_konfirmasi';
  static const viewAction = 'draf_lihat';
  static const pickAction = 'draf_kategori';
  static const _channelId = 'drafts';

  @override
  Future<void> cancel() => _plugin.cancel(id: id);

  @override
  Future<void> show(DraftNotice notice, {required bool alert}) => _plugin.show(
    id: id,
    title: notice.title,
    body: notice.body,
    payload: notice.payload,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Draf transaksi'.tr,
        channelDescription:
            'Memberi tahu pembayaran yang terdeteksi dan menunggu konfirmasi.'
                .tr,
        icon: LocalReminderNotifier.smallIcon,
        color: const Color(0xFF1C1B19),
        number: notice.count,
        channelShowBadge: true,
        // Pembaruan karena draf berkurang tidak berbunyi lagi.
        silent: !alert,
        styleInformation: BigTextStyleInformation(notice.body),
        actions: [
          for (final action in notice.actions)
            AndroidNotificationAction(
              switch (action) {
                DraftNoticeAction.confirm => confirmAction,
                DraftNoticeAction.view => viewAction,
                DraftNoticeAction.pickCategory => pickAction,
              },
              switch (action) {
                DraftNoticeAction.confirm => 'Konfirmasi'.tr,
                DraftNoticeAction.view => 'Lihat draf'.tr,
                DraftNoticeAction.pickCategory => 'Pilih kategori'.tr,
              },
              showsUserInterface: true,
              cancelNotification: false,
            ),
        ],
      ),
    ),
  );
}

/// Yang diminta dari notifikasi draf, dijalankan setelah kunci app dibuka.
sealed class DraftRequest {
  const DraftRequest();
}

/// Tombol Konfirmasi: catat draf ini langsung.
class ConfirmDraft extends DraftRequest {
  const ConfirmDraft(this.draftId);
  final int draftId;
}

/// Ketuk notifikasi, Lihat draf, atau Pilih kategori: buka halaman Draf.
/// [editDraftId] membuka lembar Ubah draf untuk draf itu.
class OpenDrafts extends DraftRequest {
  const OpenDrafts({this.editDraftId});
  final int? editDraftId;
}

/// Menjaga notifikasi draf sesuai isi halaman Draf dan meneruskan tombolnya.
class DraftNotificationService {
  DraftNotificationService({
    required DraftRepository drafts,
    CategoryRepository? categories,
    DraftNotifier? notifier,
    Future<bool> Function()? enabled,
    this.planner = const DraftNoticePlanner(),
  }) : _drafts = drafts,
       _categories = categories,
       _notifier = notifier ?? LocalDraftNotifier(),
       _enabled = enabled;

  final DraftRepository _drafts;
  final CategoryRepository? _categories;
  final DraftNotifier _notifier;
  final Future<bool> Function()? _enabled;
  final DraftNoticePlanner planner;

  /// Jumlah draf saat notifikasi terakhir; -1 sebelum pertama kali dibaca.
  int _lastCount = -1;

  /// Permintaan dari notifikasi yang belum diproses.
  DraftRequest? pending;

  /// Dipanggil saat notifikasi draf diketuk ketika app sedang berjalan.
  VoidCallback? onRequest;

  /// Memperbarui notifikasi. Berbunyi hanya bila draf bertambah sejak
  /// pembaruan sebelumnya; pembacaan pertama setelah app dibuka selalu diam.
  Future<void> refresh() async {
    try {
      final enabled = await (_enabled?.call() ?? Future.value(true));
      final drafts = enabled ? await _drafts.getPending() : <DraftModel>[];
      final names = <int, String>{
        for (final category
            in await _categories?.getAll(includeArchived: true) ?? const [])
          if (category.id != null) category.id!: category.displayName,
      };
      final notice = planner.plan(drafts, names);
      final alert = _lastCount >= 0 && drafts.length > _lastCount;
      _lastCount = drafts.length;
      if (notice == null) {
        await _notifier.cancel();
      } else {
        await _notifier.show(notice, alert: alert);
      }
    } catch (error) {
      debugPrint('Notifikasi draf gagal diperbarui: $error');
    }
  }

  /// Menangani ketukan notifikasi draf. Mengembalikan false bila bukan
  /// notifikasi draf (diteruskan ke penangan lain).
  bool handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (!DraftPayload.isDraft(payload)) return false;
    final id = DraftPayload.id(payload);
    pending = switch (response.actionId) {
      LocalDraftNotifier.confirmAction when id != null => ConfirmDraft(id),
      LocalDraftNotifier.pickAction => OpenDrafts(editDraftId: id),
      _ => const OpenDrafts(),
    };
    onRequest?.call();
    return true;
  }

  /// Mengambil permintaan yang tertunda (sekali pakai).
  DraftRequest? takePending() {
    final request = pending;
    pending = null;
    return request;
  }
}
