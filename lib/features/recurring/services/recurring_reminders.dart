import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/formatter.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../controllers/recurring_controller.dart';
import '../models/recurring_rule.dart';
import 'recurring_generator.dart';
import '../../../core/utils/date_range.dart';

/// Satu pengingat yang akan dijadwalkan.
class ReminderPlan {
  const ReminderPlan({
    required this.ruleId,
    required this.at,
    required this.title,
    required this.body,
    required this.canRecord,
    this.notificationId,
  });

  /// Aturan berulang; null untuk pengingat harian.
  final int? ruleId;
  final DateTime at;
  final String title;
  final String body;

  /// Tombol "Catat" hanya ada untuk pengingat di hari transaksi.
  final bool canRecord;

  /// Id notifikasi bila bukan id aturan (pengingat harian).
  final int? notificationId;

  bool get isDaily => ruleId == null;

  int get id => notificationId ?? ruleId!;

  /// Isi payload notifikasi: `rule:<id>` atau `daily`.
  String get payload => isDaily ? ReminderPayload.daily : 'rule:$ruleId';
}

/// Format payload notifikasi dan cara membacanya.
abstract final class ReminderPayload {
  static const daily = 'daily';

  /// Id aturan dari payload; payload lama berupa angka saja.
  static int? ruleId(String? payload) {
    if (payload == null) return null;
    return int.tryParse(
      payload.startsWith('rule:') ? payload.substring(5) : payload,
    );
  }
}

/// Pengaturan pengingat harian.
class DailyReminderConfig {
  const DailyReminderConfig({required this.enabled, this.minutes = 21 * 60});

  static const off = DailyReminderConfig(enabled: false);

  final bool enabled;

  /// Menit sejak tengah malam (21 * 60 = 21.00).
  final int minutes;
}

/// Pengingat "Sudah catat pengeluaran hari ini?" untuk 7 hari ke depan.
/// Hari ini dilewati bila sudah ada transaksi. Tanpa I/O.
class DailyReminderPlanner {
  const DailyReminderPlanner({this.days = 7});

  static const idBase = 900000;

  final int days;

  List<ReminderPlan> plan(
    DailyReminderConfig config,
    DateTime now, {
    required bool hasTransactionToday,
  }) {
    if (!config.enabled) return const [];
    final hour = config.minutes ~/ 60;
    final minute = config.minutes % 60;
    return [
      for (var offset = 0; offset < days; offset++)
        if (offset > 0 || !hasTransactionToday)
          if (DateTime(now.year, now.month, now.day + offset, hour, minute)
              case final at when at.isAfter(now))
            ReminderPlan(
              ruleId: null,
              notificationId: idBase + offset,
              at: at,
              canRecord: false,
              title: 'Sudah catat pengeluaran hari ini?'.tr,
              body: 'Ketuk untuk langsung mencatat. Cuma 10 detik.'.tr,
            ),
    ];
  }
}

/// Ketukan badan notifikasi yang menunggu diproses: buka Catat Keuangan.
class ReminderOpen {
  const ReminderOpen(this.ruleId);

  /// Aturan untuk mengisi form; null = pengingat harian (form kosong).
  final int? ruleId;
}

/// Menghitung pengingat berikutnya untuk tiap aturan. Tanpa I/O.
class RecurringReminderPlanner {
  const RecurringReminderPlanner({
    this.generator = const RecurringGenerator(),
    this.hour = 8,
  });

  final RecurringGenerator generator;

  /// Jam pengingat (waktu lokal).
  final int hour;

  List<ReminderPlan> plan(List<RecurringRule> rules, DateTime now) {
    final plans = <ReminderPlan>[];
    for (final rule in rules) {
      final id = rule.id;
      final before = rule.remindDaysBefore;
      if (id == null || before == null || !rule.isActive) continue;
      var from = DateTime(now.year, now.month, now.day);
      for (var attempt = 0; attempt < 3; attempt++) {
        final due = generator.nextOn(rule, from);
        if (due == null) break;
        final day = due.subtract(Duration(days: before));
        final at = DateTime(day.year, day.month, day.day, hour);
        if (at.isAfter(now)) {
          plans.add(_planFor(rule, id, at, before));
          break;
        }
        from = due.add(const Duration(days: 1));
      }
    }
    return plans;
  }

  ReminderPlan _planFor(RecurringRule rule, int id, DateTime at, int before) {
    final amount = formatIdr(rule.amount);
    final sameDay = before == 0;
    return ReminderPlan(
      ruleId: id,
      at: at,
      canRecord: sameDay,
      title: sameDay
          ? '@name hari ini · @amount'.trParams({
              'name': rule.name,
              'amount': amount,
            })
          : 'Besok: @name · @amount'.trParams({
              'name': rule.name,
              'amount': amount,
            }),
      body: sameDay
          ? 'Transaksi berulang. Ketuk Catat untuk mencatatnya.'.tr
          : 'Transaksi berulang besok. Siapkan saldonya.'.tr,
    );
  }
}

/// Lapisan notifikasi, dipisah supaya layanan bisa dites tanpa plugin.
abstract interface class ReminderNotifier {
  Future<void> cancelAll();
  Future<void> schedule(ReminderPlan plan);
  Future<bool> requestPermission();
}

/// Notifikasi lokal lewat flutter_local_notifications. Jadwal memakai waktu
/// absolut (UTC) dan mode tidak eksak, jadi tidak butuh izin alarm eksak dan
/// tidak berjalan terus di latar.
class LocalReminderNotifier implements ReminderNotifier {
  LocalReminderNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const recordAction = 'catat';
  static const skipAction = 'lewati';
  static const _channelId = 'recurring_reminders';
  static const _dailyChannelId = 'daily_reminder';

  /// Ikon kecil monokrom logo Tally (res/drawable/ic_stat_tally.xml).
  static const smallIcon = 'ic_stat_tally';
  static const _ink = Color(0xFF1C1B19);

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;

  @override
  Future<void> schedule(ReminderPlan plan) => _plugin.zonedSchedule(
    id: plan.id,
    scheduledDate: tz.TZDateTime.from(plan.at, tz.UTC),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    title: plan.title,
    body: plan.body,
    payload: plan.payload,
    notificationDetails: NotificationDetails(
      android: plan.isDaily
          ? AndroidNotificationDetails(
              _dailyChannelId,
              'Pengingat harian'.tr,
              channelDescription:
                  'Mengingatkan mencatat bila hari ini belum ada transaksi.'.tr,
              icon: smallIcon,
              color: _ink,
            )
          : _recurringDetails(plan),
    ),
  );

  AndroidNotificationDetails _recurringDetails(ReminderPlan plan) =>
      AndroidNotificationDetails(
        _channelId,
        'Pengingat transaksi berulang'.tr,
        channelDescription: 'Mengingatkan transaksi berulang di tanggalnya.'.tr,
        icon: smallIcon,
        color: _ink,
        actions: [
          if (plan.canRecord)
            AndroidNotificationAction(
              recordAction,
              'Catat'.tr,
              showsUserInterface: true,
              cancelNotification: true,
            ),
          AndroidNotificationAction(
            skipAction,
            'Lewati'.tr,
            cancelNotification: true,
          ),
        ],
      );
}

/// Menjadwalkan ulang pengingat dan menangani ketukan notifikasi.
///
/// "Catat" membuka app; setelah kunci dibuka, transaksi untuk aturan itu
/// dicatat (lihat [consumePendingRecord]). "Lewati" hanya menutup notifikasi.
/// Mengetuk badan notifikasi membuka Catat Keuangan (lihat [takePendingOpen]).
class RecurringReminderService {
  RecurringReminderService({
    required RecurringStore store,
    required TransactionRepository transactions,
    ReminderNotifier? notifier,
    this.planner = const RecurringReminderPlanner(),
    this.dailyPlanner = const DailyReminderPlanner(),
    this.generator = const RecurringGenerator(),
    Future<DailyReminderConfig> Function()? dailyConfig,
    DateTime Function()? clock,
  }) : _store = store,
       _transactions = transactions,
       _notifier = notifier ?? LocalReminderNotifier(),
       _dailyConfig = dailyConfig,
       _clock = clock ?? DateTime.now;

  final RecurringStore _store;
  final TransactionRepository _transactions;
  final ReminderNotifier _notifier;
  final RecurringReminderPlanner planner;
  final DailyReminderPlanner dailyPlanner;
  final RecurringGenerator generator;
  final Future<DailyReminderConfig> Function()? _dailyConfig;
  final DateTime Function() _clock;

  /// Aturan yang tombol "Catat"-nya ditekan dan belum diproses.
  int? pendingRecordRuleId;

  /// Dipanggil saat "Catat" ditekan ketika app sedang berjalan.
  VoidCallback? onRecordRequested;

  /// Badan notifikasi yang diketuk dan belum diproses.
  ReminderOpen? pendingOpen;

  /// Dipanggil saat badan notifikasi diketuk ketika app sedang berjalan.
  VoidCallback? onOpenRequested;

  /// Penangan notifikasi lain yang memakai plugin yang sama (mis. draf).
  /// Mengembalikan true bila respons sudah ditangani.
  final responseHandlers = <bool Function(NotificationResponse)>[];

  /// Menyiapkan plugin dan membaca notifikasi yang membuka app.
  Future<void> init() async {
    final notifier = _notifier;
    if (notifier is! LocalReminderNotifier) return;
    try {
      await notifier.plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(
            LocalReminderNotifier.smallIcon,
          ),
        ),
        onDidReceiveNotificationResponse: handleResponse,
      );
      final launch = await notifier.plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && response != null) {
        handleResponse(response);
      }
    } catch (error) {
      debugPrint('Pengingat tidak bisa disiapkan: $error');
    }
  }

  void handleResponse(NotificationResponse response) {
    for (final handler in responseHandlers) {
      if (handler(response)) return;
    }
    final action = response.actionId;
    if (action == LocalReminderNotifier.recordAction) {
      pendingRecordRuleId = ReminderPayload.ruleId(response.payload);
      onRecordRequested?.call();
      return;
    }
    if (action != null && action.isNotEmpty) return;
    final payload = response.payload;
    if (payload == ReminderPayload.daily) {
      pendingOpen = const ReminderOpen(null);
    } else {
      final ruleId = ReminderPayload.ruleId(payload);
      if (ruleId == null) return;
      pendingOpen = ReminderOpen(ruleId);
    }
    onOpenRequested?.call();
  }

  /// Mengambil ketukan badan notifikasi yang tertunda (sekali pakai).
  ReminderOpen? takePendingOpen() {
    final open = pendingOpen;
    pendingOpen = null;
    return open;
  }

  Future<RecurringRule?> ruleById(int id) async =>
      (await _store.getAll()).where((r) => r.id == id).firstOrNull;

  Future<bool> requestPermission() => _notifier.requestPermission();

  /// Membatalkan semua pengingat lalu menjadwalkan yang berikutnya.
  Future<void> reschedule() async {
    try {
      final now = _clock();
      final plans = [
        ...planner.plan(await _store.getAll(), now),
        ...await _dailyPlans(now),
      ];
      await _notifier.cancelAll();
      for (final plan in plans) {
        await _notifier.schedule(plan);
      }
    } catch (error) {
      debugPrint('Pengingat gagal dijadwalkan: $error');
    }
  }

  Future<List<ReminderPlan>> _dailyPlans(DateTime now) async {
    final load = _dailyConfig;
    if (load == null) return const [];
    final config = await load();
    if (!config.enabled) return const [];
    final today = DateTime(now.year, now.month, now.day);
    final count = await _transactions.count(
      range: DateRange(start: today, end: today),
    );
    return dailyPlanner.plan(config, now, hasTransactionToday: count > 0);
  }

  /// Mencatat transaksi untuk aturan yang tombol "Catat"-nya ditekan.
  /// Mengembalikan nama aturan bila ada yang tercatat.
  Future<String?> consumePendingRecord() async {
    final ruleId = pendingRecordRuleId;
    pendingRecordRuleId = null;
    if (ruleId == null) return null;
    final rule = (await _store.getAll())
        .where((r) => r.id == ruleId)
        .firstOrNull;
    if (rule == null) return null;
    final dues = generator.dueOn(rule, _clock());
    if (dues.isEmpty) return null;
    final now = DateTime.now();
    for (final due in dues) {
      await _transactions.insert(
        TransactionModel(
          type: rule.type == RecurringType.income
              ? TransactionType.income
              : TransactionType.expense,
          title: rule.name,
          amount: rule.amount,
          transactionDate: due,
          categoryId: rule.categoryId,
          merchantOrSource: rule.name,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _store.markGenerated(ruleId, due);
    }
    return rule.name;
  }
}
