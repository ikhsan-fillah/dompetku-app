import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/drafts/models/draft_model.dart';
import 'package:dompetku_app/features/drafts/repositories/draft_repository.dart';
import 'package:dompetku_app/features/drafts/services/draft_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

DraftModel _draft(
  int id, {
  String source = 'GoPay',
  int amount = 25000,
  int? categoryId = 3,
  String? merchant = 'Ojek Online',
}) => DraftModel(
  id: id,
  source: source,
  kind: TransactionType.expense,
  amount: amount,
  merchant: merchant,
  categoryId: categoryId,
  detectedAt: DateTime.utc(2026, 10, 25, 7),
  dedupeKey: 'k$id',
);

class _Drafts implements DraftRepository {
  _Drafts(this.items);

  List<DraftModel> items;

  @override
  Future<List<DraftModel>> getPending() async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifier implements DraftNotifier {
  final shown = <(DraftNotice, bool)>[];
  var cancelled = 0;

  @override
  Future<void> cancel() async => cancelled++;

  @override
  Future<void> show(DraftNotice notice, {required bool alert}) async =>
      shown.add((notice, alert));
}

NotificationResponse _response(String payload, {String? action}) =>
    NotificationResponse(
      notificationResponseType: action == null
          ? NotificationResponseType.selectedNotification
          : NotificationResponseType.selectedNotificationAction,
      actionId: action,
      payload: payload,
    );

void main() {
  const planner = DraftNoticePlanner();

  group('DraftNoticePlanner', () {
    test('satu draf berkategori: Konfirmasi dan Lihat draf', () {
      final notice = planner.plan([_draft(1)], {3: 'Transport'})!;

      expect(notice.title, 'Draf baru · GoPay − Rp 25.000');
      expect(notice.body, contains('Ojek Online · kategori Transport.'));
      expect(notice.count, 1);
      expect(notice.actions, [
        DraftNoticeAction.confirm,
        DraftNoticeAction.view,
      ]);
      expect(notice.payload, 'draft:1');
    });

    test('draf tanpa kategori hanya punya Pilih kategori', () {
      final notice = planner.plan([_draft(2, categoryId: null)], const {})!;

      expect(notice.body, contains('Pilih kategori dulu'));
      expect(notice.actions, [DraftNoticeAction.pickCategory]);
    });

    test('beberapa draf digabung, angka = jumlah draf', () {
      final notice = planner.plan([
        _draft(1),
        _draft(2, source: 'BRI', amount: 150000),
        _draft(3, source: 'OVO', amount: 18500),
        _draft(4, source: 'DANA', amount: 9000),
      ], const {})!;

      expect(notice.title, '4 draf menunggu konfirmasi');
      expect(
        notice.body,
        'GoPay − 25.000 · BRI − 150.000 · OVO − 18.500 · '
        '+1 lainnya',
      );
      expect(notice.count, 4);
      expect(notice.actions, [DraftNoticeAction.view]);
      expect(notice.payload, DraftPayload.all);
    });

    test('tanpa draf tidak ada notifikasi', () {
      expect(planner.plan(const [], const {}), isNull);
    });
  });

  group('DraftNotificationService', () {
    test('berbunyi hanya saat draf bertambah; habis = dibatalkan', () async {
      final drafts = _Drafts([_draft(1)]);
      final notifier = _Notifier();
      final service = DraftNotificationService(
        drafts: drafts,
        notifier: notifier,
      );

      await service.refresh(); // pembacaan pertama: diam
      drafts.items = [_draft(1), _draft(2)];
      await service.refresh(); // bertambah: berbunyi
      drafts.items = [_draft(2)];
      await service.refresh(); // berkurang: diam
      drafts.items = [];
      await service.refresh();

      expect(notifier.shown.map((s) => s.$2), [false, true, false]);
      expect(notifier.shown.map((s) => s.$1.count), [1, 2, 1]);
      expect(notifier.cancelled, 1);
    });

    test('dimatikan di Profil: notifikasi dibatalkan', () async {
      final notifier = _Notifier();
      final service = DraftNotificationService(
        drafts: _Drafts([_draft(1)]),
        notifier: notifier,
        enabled: () async => false,
      );

      await service.refresh();

      expect(notifier.shown, isEmpty);
      expect(notifier.cancelled, 1);
    });

    test('tombol notifikasi diterjemahkan ke permintaan', () {
      final service = DraftNotificationService(
        drafts: _Drafts(const []),
        notifier: _Notifier(),
      );
      var calls = 0;
      service.onRequest = () => calls++;

      expect(
        service.handleResponse(
          _response('draft:5', action: LocalDraftNotifier.confirmAction),
        ),
        isTrue,
      );
      expect((service.takePending() as ConfirmDraft).draftId, 5);

      service.handleResponse(
        _response('draft:6', action: LocalDraftNotifier.pickAction),
      );
      expect((service.takePending() as OpenDrafts).editDraftId, 6);

      service.handleResponse(_response(DraftPayload.all));
      expect((service.takePending() as OpenDrafts).editDraftId, isNull);

      // Payload pengingat berulang bukan urusan layanan draf.
      expect(service.handleResponse(_response('rule:1')), isFalse);
      expect(service.takePending(), isNull);
      expect(calls, 3);
    });
  });
}
