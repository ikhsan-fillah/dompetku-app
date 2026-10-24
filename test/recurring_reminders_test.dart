import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/recurring/controllers/recurring_controller.dart';
import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:dompetku_app/features/recurring/services/recurring_reminders.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringRule _rule({
  int id = 1,
  int? remind = 0,
  bool active = true,
  DateTime? lastGenerated,
}) => RecurringRule(
  id: id,
  name: 'Spotify',
  type: RecurringType.expense,
  categoryId: 3,
  amount: 55000,
  frequency: RecurringFrequency.monthly,
  dayOfMonth: 5,
  startDate: DateTime(2026, 1, 5),
  mode: RecurringMode.ask,
  isActive: active,
  lastGeneratedOn: lastGenerated,
  remindDaysBefore: remind,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _Store implements RecurringStore {
  _Store(this.rules);

  List<RecurringRule> rules;
  final generated = <DateTime>[];

  @override
  Future<List<RecurringRule>> getAll() async => rules;

  @override
  Future<void> markGenerated(int id, DateTime day) async {
    generated.add(day);
    rules = [
      for (final r in rules)
        if (r.id == id) r.withLastGenerated(day) else r,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transactions implements TransactionRepository {
  _Transactions({this.todayCount = 0});

  final int todayCount;
  final inserted = <TransactionModel>[];

  @override
  Future<int> count({DateRange? range}) async => todayCount;

  @override
  Future<int> insert(TransactionModel transaction) async {
    inserted.add(transaction);
    return inserted.length;
  }

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifier implements ReminderNotifier {
  final scheduled = <ReminderPlan>[];
  var cancelled = 0;

  @override
  Future<void> cancelAll() async => cancelled++;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(ReminderPlan plan) async => scheduled.add(plan);
}

void main() {
  const planner = RecurringReminderPlanner();

  group('RecurringReminderPlanner', () {
    test('pengingat hari H dijadwalkan pukul 08.00 di tanggal berikutnya', () {
      final plans = planner.plan([_rule()], DateTime(2026, 10, 2, 12));

      final plan = plans.single;
      expect(plan.at, DateTime(2026, 10, 5, 8));
      expect(plan.canRecord, isTrue);
      expect(plan.title, contains('Spotify hari ini'));
    });

    test('lewat jam 08.00 di hari H, pindah ke bulan berikutnya', () {
      final plans = planner.plan([_rule()], DateTime(2026, 10, 5, 9));

      expect(plans.single.at, DateTime(2026, 11, 5, 8));
    });

    test('sehari sebelum: tanggal 4 pukul 08.00, tanpa tombol Catat', () {
      final plans = planner.plan([_rule(remind: 1)], DateTime(2026, 10, 2));

      expect(plans.single.at, DateTime(2026, 10, 4, 8));
      expect(plans.single.canRecord, isFalse);
      expect(plans.single.title, startsWith('Besok: Spotify'));
    });

    test('pengingat mati atau aturan nonaktif tidak dijadwalkan', () {
      final plans = planner.plan([
        _rule(id: 1, remind: null),
        _rule(id: 2, active: false),
      ], DateTime(2026, 10, 2));

      expect(plans, isEmpty);
    });
  });

  group('RecurringReminderService', () {
    test('reschedule membatalkan lalu menjadwalkan ulang', () async {
      final notifier = _Notifier();
      final service = RecurringReminderService(
        store: _Store([_rule(id: 1), _rule(id: 2, remind: null)]),
        transactions: _Transactions(),
        notifier: notifier,
        clock: () => DateTime(2026, 10, 2),
      );

      await service.reschedule();

      expect(notifier.cancelled, 1);
      expect(notifier.scheduled.map((p) => p.ruleId), [1]);
    });

    test('tombol Catat mencatat transaksi hari itu sekali saja', () async {
      final store = _Store([_rule(lastGenerated: DateTime(2026, 9, 5))]);
      final transactions = _Transactions();
      final service = RecurringReminderService(
        store: store,
        transactions: transactions,
        notifier: _Notifier(),
        clock: () => DateTime(2026, 10, 5, 8, 5),
      );

      service.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: LocalReminderNotifier.recordAction,
          payload: '1',
        ),
      );
      final name = await service.consumePendingRecord();

      expect(name, 'Spotify');
      expect(transactions.inserted.single.amount, 55000);
      expect(
        transactions.inserted.single.transactionDate,
        DateTime(2026, 10, 5),
      );
      expect(store.generated, [DateTime(2026, 10, 5)]);

      // Tidak ada aksi tertunda lagi.
      expect(await service.consumePendingRecord(), isNull);
      expect(transactions.inserted, hasLength(1));
    });

    test('ketuk badan notifikasi (bukan Catat) tidak mencatat', () async {
      final transactions = _Transactions();
      final service = RecurringReminderService(
        store: _Store([_rule()]),
        transactions: transactions,
        notifier: _Notifier(),
        clock: () => DateTime(2026, 10, 5, 9),
      );

      service.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '1',
        ),
      );

      expect(await service.consumePendingRecord(), isNull);
      expect(transactions.inserted, isEmpty);
    });
  });

  group('DailyReminderPlanner', () {
    const daily = DailyReminderPlanner();
    const config = DailyReminderConfig(enabled: true);

    test('tujuh hari ke depan pukul 21.00, mulai hari ini', () {
      final plans = daily.plan(
        config,
        DateTime(2026, 10, 24, 9),
        hasTransactionToday: false,
      );

      expect(plans, hasLength(7));
      expect(plans.first.at, DateTime(2026, 10, 24, 21));
      expect(plans.last.at, DateTime(2026, 10, 30, 21));
      expect(plans.first.isDaily, isTrue);
      expect(plans.first.payload, ReminderPayload.daily);
      expect(plans.map((p) => p.id).toSet(), hasLength(7));
    });

    test('hari ini dilewati bila sudah ada transaksi', () {
      final plans = daily.plan(
        config,
        DateTime(2026, 10, 24, 9),
        hasTransactionToday: true,
      );

      expect(plans.first.at, DateTime(2026, 10, 25, 21));
      expect(plans, hasLength(6));
    });

    test('lewat jamnya, mulai besok; jam bisa diatur; mati = kosong', () {
      final late = daily.plan(
        const DailyReminderConfig(enabled: true, minutes: 19 * 60 + 30),
        DateTime(2026, 10, 24, 20),
        hasTransactionToday: false,
      );
      expect(late.first.at, DateTime(2026, 10, 25, 19, 30));

      expect(
        daily.plan(
          DailyReminderConfig.off,
          DateTime(2026, 10, 24),
          hasTransactionToday: false,
        ),
        isEmpty,
      );
    });
  });

  group('ketuk notifikasi', () {
    RecurringReminderService service({_Transactions? transactions}) =>
        RecurringReminderService(
          store: _Store([_rule()]),
          transactions: transactions ?? _Transactions(),
          notifier: _Notifier(),
          dailyConfig: () async => const DailyReminderConfig(enabled: true),
          clock: () => DateTime(2026, 10, 2, 9),
        );

    test('badan pengingat berulang membuka form terisi aturan itu', () async {
      final reminders = service();
      var opened = 0;
      reminders.onOpenRequested = () => opened++;

      reminders.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'rule:1',
        ),
      );

      expect(opened, 1);
      final open = reminders.takePendingOpen();
      expect(open?.ruleId, 1);
      expect((await reminders.ruleById(1))?.name, 'Spotify');
      expect(reminders.takePendingOpen(), isNull);
    });

    test('badan pengingat harian membuka form kosong', () {
      final reminders = service();

      reminders.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: ReminderPayload.daily,
        ),
      );

      final open = reminders.takePendingOpen();
      expect(open, isNotNull);
      expect(open!.ruleId, isNull);
    });

    test('Lewati tidak membuka apa pun', () {
      final reminders = service();

      reminders.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: LocalReminderNotifier.skipAction,
          payload: 'rule:1',
        ),
      );

      expect(reminders.takePendingOpen(), isNull);
      expect(reminders.pendingRecordRuleId, isNull);
    });

    test('Catat membaca payload baru maupun lama', () {
      final reminders = service();

      reminders.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: LocalReminderNotifier.recordAction,
          payload: 'rule:1',
        ),
      );

      expect(reminders.pendingRecordRuleId, 1);
      expect(reminders.takePendingOpen(), isNull);
    });

    test('reschedule ikut menjadwalkan pengingat harian', () async {
      final notifier = _Notifier();
      final reminders = RecurringReminderService(
        store: _Store([_rule()]),
        transactions: _Transactions(todayCount: 2),
        notifier: notifier,
        dailyConfig: () async => const DailyReminderConfig(enabled: true),
        clock: () => DateTime(2026, 10, 2, 9),
      );

      await reminders.reschedule();

      final daily = notifier.scheduled.where((p) => p.isDaily).toList();
      expect(daily, hasLength(6));
      expect(daily.first.at, DateTime(2026, 10, 3, 21));
      expect(notifier.scheduled.where((p) => !p.isDaily), hasLength(1));
    });
  });
}
