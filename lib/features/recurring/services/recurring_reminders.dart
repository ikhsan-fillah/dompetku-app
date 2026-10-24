import 'dart:async';

import 'package:flutter/foundation.dart';
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

/// Satu pengingat yang akan dijadwalkan.
class ReminderPlan {
  const ReminderPlan({
    required this.ruleId,
    required this.at,
    required this.title,
    required this.body,
    required this.canRecord,
  });

  final int ruleId;
  final DateTime at;
  final String title;
  final String body;

  /// Tombol "Catat" hanya ada untuk pengingat di hari transaksi.
  final bool canRecord;
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
    id: plan.ruleId,
    scheduledDate: tz.TZDateTime.from(plan.at, tz.UTC),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    title: plan.title,
    body: plan.body,
    payload: '${plan.ruleId}',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Pengingat transaksi berulang'.tr,
        channelDescription: 'Mengingatkan transaksi berulang di tanggalnya.'.tr,
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
      ),
    ),
  );
}

/// Menjadwalkan ulang pengingat dan menangani tombol "Catat".
///
/// "Catat" membuka app; setelah kunci dibuka, transaksi untuk aturan itu
/// dicatat (lihat [consumePendingRecord]). "Lewati" hanya menutup notifikasi.
class RecurringReminderService {
  RecurringReminderService({
    required RecurringStore store,
    required TransactionRepository transactions,
    ReminderNotifier? notifier,
    this.planner = const RecurringReminderPlanner(),
    this.generator = const RecurringGenerator(),
    DateTime Function()? clock,
  }) : _store = store,
       _transactions = transactions,
       _notifier = notifier ?? LocalReminderNotifier(),
       _clock = clock ?? DateTime.now;

  final RecurringStore _store;
  final TransactionRepository _transactions;
  final ReminderNotifier _notifier;
  final RecurringReminderPlanner planner;
  final RecurringGenerator generator;
  final DateTime Function() _clock;

  /// Aturan yang tombol "Catat"-nya ditekan dan belum diproses.
  int? pendingRecordRuleId;

  /// Dipanggil saat "Catat" ditekan ketika app sedang berjalan.
  VoidCallback? onRecordRequested;

  /// Menyiapkan plugin dan membaca notifikasi yang membuka app.
  Future<void> init() async {
    final notifier = _notifier;
    if (notifier is! LocalReminderNotifier) return;
    try {
      await notifier.plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
    if (response.actionId != LocalReminderNotifier.recordAction) return;
    pendingRecordRuleId = int.tryParse(response.payload ?? '');
    onRecordRequested?.call();
  }

  Future<bool> requestPermission() => _notifier.requestPermission();

  /// Membatalkan semua pengingat lalu menjadwalkan yang berikutnya.
  Future<void> reschedule() async {
    try {
      final plans = planner.plan(await _store.getAll(), _clock());
      await _notifier.cancelAll();
      for (final plan in plans) {
        await _notifier.schedule(plan);
      }
    } catch (error) {
      debugPrint('Pengingat gagal dijadwalkan: $error');
    }
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
