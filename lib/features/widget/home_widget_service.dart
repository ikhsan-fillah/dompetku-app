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
import '../../core/utils/percent_rounding.dart';
import '../budget/models/budget_model.dart';
import '../budget/repositories/budget_repository.dart';
import '../category/models/category_model.dart';
import '../category/repositories/category_repository.dart';
import '../transaction/models/transaction_model.dart';
import '../transaction/repositories/transaction_repository.dart';

/// Teks siap tampil untuk widget layar utama. Semua diformat di sini (bahasa
/// dan penyamaran nominal), jadi kode Android hanya menampilkannya.
class WidgetSnapshot {
  const WidgetSnapshot(
    this.values, {
    required this.budgetProgress,
    this.categorySlices = '',
  });

  final Map<String, String> values;

  /// 0 sampai 100, untuk batang progres widget anggaran.
  final int budgetProgress;

  /// Potongan donat widget kategori: "AARRGGBB:pecahan;..." urut terbesar.
  final String categorySlices;

  static const hidden = 'Rp ••••••';

  /// Kategori di donat; sisanya digabung jadi satu potongan abu.
  static const maxSlices = 5;
  static const _otherColor = 0xFF8A8F8B;

  /// Nominal ringkas untuk ruang sempit: 850 rb, 1,58 jt, 2,1 M.
  static String compact(int value) => formatCompactIdr(value);

  /// Menyusun isi widget dari transaksi bulan [month] dan anggaran aktif.
  factory WidgetSnapshot.build({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required DateTime now,
    required bool hideAmounts,
    Map<int, CategoryModel> categories = const {},
  }) {
    final today = DateTime(now.year, now.month, now.day);
    var income = 0;
    var expense = 0;
    final byCategory = <int, int>{};
    for (final t in transactions) {
      final date = t.transactionDate.toLocal();
      if (date.year != now.year || date.month != now.month) continue;
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
        byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
      }
    }
    final ranked = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = ranked.take(maxSlices).toList();
    final rest = ranked.skip(maxSlices).fold<int>(0, (sum, e) => sum + e.value);
    final percents = roundPercentages([
      for (final e in ranked) e.value.toDouble(),
    ]);
    String hex(int color) =>
        (color & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase();
    final slices = expense == 0
        ? ''
        : [
            for (final e in shown)
              '${hex(categories[e.key]?.colorValue ?? _otherColor)}:'
                  '${(e.value / expense).toStringAsFixed(4)}',
            if (rest > 0)
              '${hex(_otherColor)}:${(rest / expense).toStringAsFixed(4)}',
          ].join(';');
    String topName(int index) {
      if (index >= ranked.length) return '';
      final name = categories[ranked[index].key]?.displayName ?? 'Lainnya'.tr;
      return '$name ${percents[index]}%';
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

    return WidgetSnapshot(
      {
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
        'cat_label': 'Pengeluaran @month'.trParams({
          'month': AppLanguage.monthShort(now.month),
        }),
        'cat_total': expense == 0
            ? ''
            : (hideAmounts ? '••••' : compact(expense)),
        'cat_caption': expense == 0
            ? 'Belum ada pengeluaran'.tr
            : 'bulan ini'.tr,
        'cat_name1': topName(0),
        'cat_name2': topName(1),
        'cat_name3': topName(2),
      },
      budgetProgress: percent.clamp(0, 100),
      categorySlices: slices,
    );
  }
}

/// Aksi yang diminta dari widget (mis. tombol "+ Pengeluaran").
enum WidgetAction { open, addExpense, addIncome, openBudget }

/// Memperbarui widget saat data berubah dan meneruskan ketukan widget ke app.
class HomeWidgetService {
  HomeWidgetService({
    required TransactionRepository transactions,
    required BudgetRepository budgets,
    CategoryRepository? categories,
    SharedPrefsService? preferences,
    DateTime Function()? clock,
  }) : _transactions = transactions,
       _budgets = budgets,
       _categories = categories,
       _preferences = preferences ?? SharedPrefsService(),
       _clock = clock ?? DateTime.now;

  static const _balanceProvider = 'com.fillah.dompetku.BalanceWidgetProvider';
  static const _budgetProvider = 'com.fillah.dompetku.BudgetWidgetProvider';
  static const _categoryProvider = 'com.fillah.dompetku.CategoryWidgetProvider';

  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final CategoryRepository? _categories;
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
      final categories = await _categories?.getAll(includeArchived: true);
      final snapshot = WidgetSnapshot.build(
        transactions: transactions,
        budgets: budgets,
        now: now,
        hideAmounts: hide,
        categories: {
          for (final category in categories ?? const <CategoryModel>[])
            if (category.id != null) category.id!: category,
        },
      );
      for (final entry in snapshot.values.entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }
      await HomeWidget.saveWidgetData<int>(
        'budget_progress',
        snapshot.budgetProgress,
      );
      await HomeWidget.saveWidgetData<String>(
        'cat_slices',
        snapshot.categorySlices,
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _balanceProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: _budgetProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: _categoryProvider);
    } catch (error) {
      debugPrint('Widget gagal diperbarui: $error');
    }
  }
}
