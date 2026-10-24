import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/constant/domain_enums.dart';
import '../../core/i18n/app_language.dart';
import '../../core/services/data_refresh_service.dart';
import '../../core/services/shared_prefs_service.dart';
import '../../core/utils/date_range.dart';
import '../../core/utils/formatter.dart';
import '../budget/models/budget_model.dart';
import '../budget/repositories/budget_repository.dart';
import '../transaction/models/transaction_model.dart';
import '../transaction/repositories/transaction_repository.dart';

/// Teks siap tampil untuk widget layar utama. Semua diformat di sini (bahasa
/// dan penyamaran nominal), jadi kode Android hanya menampilkannya.
class WidgetSnapshot {
  const WidgetSnapshot(this.values, {required this.budgetProgress});

  final Map<String, String> values;

  /// 0 sampai 100, untuk batang progres widget anggaran.
  final int budgetProgress;

  static const hidden = 'Rp ••••••';

  /// Menyusun isi widget dari transaksi bulan [month] dan anggaran aktif.
  factory WidgetSnapshot.build({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required DateTime now,
    required bool hideAmounts,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    var income = 0;
    var expense = 0;
    for (final t in transactions) {
      final date = t.transactionDate.toLocal();
      if (date.year != now.year || date.month != now.month) continue;
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    var limit = 0;
    var used = 0;
    for (final budget in budgets) {
      if (budget.isArchived) continue;
      final start = DateTime(
        budget.startDate.year,
        budget.startDate.month,
        budget.startDate.day,
      );
      final end = DateTime(
        budget.endDate.year,
        budget.endDate.month,
        budget.endDate.day,
      );
      if (today.isBefore(start) || today.isAfter(end)) continue;
      limit += budget.amountLimit;
      for (final t in transactions) {
        if (t.type != TransactionType.expense) continue;
        final date = t.transactionDate.toLocal();
        final day = DateTime(date.year, date.month, date.day);
        if (day.isBefore(start) || day.isAfter(end)) continue;
        if (budget.categoryId != null && t.categoryId != budget.categoryId) {
          continue;
        }
        used += t.amount;
      }
    }

    String money(int value) => hideAmounts ? hidden : formatIdr(value);
    String plain(int value) => hideAmounts ? '••••' : formatIdrPlain(value);
    final month = AppLanguage.monthLong(now.month);
    final percent = limit == 0 ? 0 : (used * 100 / limit).round();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    return WidgetSnapshot({
      'label': '@month · sisa saldo'.trParams({'month': month}),
      'updated': '$hh.$mm',
      'balance': money(income - expense),
      'income': '+ ${plain(income)}',
      'expense': '− ${plain(expense)}',
      'add_expense': '+ ${'Pengeluaran'.tr}',
      'add_income': '+ ${'Pemasukan'.tr}',
      'budget_label': 'Anggaran @month'.trParams({
        'month': AppLanguage.monthShort(now.month),
      }),
      'budget_percent': limit == 0 ? '–' : '$percent%',
      'budget_caption': limit == 0 ? 'belum ada anggaran'.tr : 'terpakai'.tr,
      'budget_left': limit == 0
          ? ''
          : (limit - used >= 0
                ? 'sisa @amount'.trParams({'amount': plain(limit - used)})
                : 'lewat @amount'.trParams({'amount': plain(used - limit)})),
    }, budgetProgress: percent.clamp(0, 100));
  }
}

/// Aksi yang diminta dari widget (mis. tombol "+ Pengeluaran").
enum WidgetAction { open, addExpense, addIncome, openBudget }

/// Memperbarui widget saat data berubah dan meneruskan ketukan widget ke app.
class HomeWidgetService {
  HomeWidgetService({
    required TransactionRepository transactions,
    required BudgetRepository budgets,
    SharedPrefsService? preferences,
    DateTime Function()? clock,
  }) : _transactions = transactions,
       _budgets = budgets,
       _preferences = preferences ?? SharedPrefsService(),
       _clock = clock ?? DateTime.now;

  static const _balanceProvider = 'com.fillah.dompetku.BalanceWidgetProvider';
  static const _budgetProvider = 'com.fillah.dompetku.BudgetWidgetProvider';

  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final SharedPrefsService _preferences;
  final DateTime Function() _clock;

  /// Aksi dari widget yang belum dijalankan (menunggu kunci dibuka).
  WidgetAction? pendingAction;

  /// Dipanggil saat widget diketuk ketika app sedang berjalan.
  VoidCallback? onAction;

  Worker? _worker;
  Timer? _debounce;

  static WidgetAction? actionFor(Uri? uri) {
    if (uri == null || uri.scheme != 'tally') return null;
    final path = '${uri.host}${uri.path}';
    return switch (path) {
      'catat/expense' => WidgetAction.addExpense,
      'catat/income' => WidgetAction.addIncome,
      'anggaran' => WidgetAction.openBudget,
      _ => WidgetAction.open,
    };
  }

  Future<void> init() async {
    try {
      pendingAction = actionFor(
        await HomeWidget.initiallyLaunchedFromHomeWidget(),
      );
      HomeWidget.widgetClicked.listen((uri) {
        final action = actionFor(uri);
        if (action == null) return;
        pendingAction = action;
        onAction?.call();
      });
    } catch (error) {
      debugPrint('Widget tidak bisa disiapkan: $error');
    }
    if (Get.isRegistered<DataRefreshService>()) {
      _worker = ever<int>(Get.find<DataRefreshService>().version, (_) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 600), update);
      });
    }
  }

  void dispose() {
    _worker?.dispose();
    _debounce?.cancel();
  }

  WidgetAction? takePendingAction() {
    final action = pendingAction;
    pendingAction = null;
    return action;
  }

  /// Menghitung ulang isi widget dan meminta Android menggambar ulang.
  Future<void> update() async {
    try {
      final now = _clock();
      final hide = await _preferences.getWidgetHideAmounts();
      final budgets = await _budgets.getAll();
      var start = DateTime(now.year, now.month);
      var end = DateTime(now.year, now.month + 1, 0);
      for (final budget in budgets) {
        if (budget.startDate.isBefore(start)) start = budget.startDate;
        if (budget.endDate.isAfter(end)) end = budget.endDate;
      }
      final transactions = await _transactions.getAll(
        range: DateRange(start: start, end: end),
      );
      final snapshot = WidgetSnapshot.build(
        transactions: transactions,
        budgets: budgets,
        now: now,
        hideAmounts: hide,
      );
      for (final entry in snapshot.values.entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }
      await HomeWidget.saveWidgetData<int>(
        'budget_progress',
        snapshot.budgetProgress,
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _balanceProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: _budgetProvider);
    } catch (error) {
      debugPrint('Widget gagal diperbarui: $error');
    }
  }
}
