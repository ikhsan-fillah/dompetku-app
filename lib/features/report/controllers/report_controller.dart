import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../category/repositories/category_repository.dart';
import '../../dashboard/models/dashboard_summary_model.dart';
import '../../dashboard/services/financial_calculation_service.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../../trend/models/monthly_trend.dart';
import '../../trend/services/monthly_trend_service.dart';

class ReportData {
  const ReportData({
    required this.summary,
    required this.expensesByCategory,
    required this.expenseChange,
    required this.dailyAverage,
    this.highestSpendingDay,
    this.highestSpendingDayAmount = 0,
    this.topMerchant,
    this.topMerchantCount = 0,
    this.dailySpending = const [],
    this.previousExpense = 0,
    this.incomeTrend,
    this.isEmpty = false,
  });

  final DashboardSummaryModel summary;
  final List<ReportCategoryTotal> expensesByCategory;
  final double expenseChange;
  final double dailyAverage;
  final DateTime? highestSpendingDay;
  final int highestSpendingDayAmount;
  final String? topMerchant;
  final int topMerchantCount;

  /// Pengeluaran per hari, dimulai dari hari pertama rentang.
  final List<int> dailySpending;
  final int previousExpense;

  /// Pemasukan per hari pada bulan laporan, untuk kartu Tren pemasukan.
  final MonthlyTrend? incomeTrend;

  /// Tidak ada transaksi sama sekali pada periode. Laporan tetap tampil
  /// dengan isi kosong, bukan pesan saja.
  final bool isEmpty;
}

class ReportCategoryTotal {
  const ReportCategoryTotal({
    required this.categoryId,
    required this.name,
    required this.colorValue,
    required this.amount,
  });

  final int categoryId;
  final String name;
  final int colorValue;
  final int amount;
}

class ReportController extends GetxController {
  ReportController(this._transactions, this._categories, this._calculations);

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final FinancialCalculationService _calculations;
  final range = DateRange.fromPreset(DateRangePreset.currentMonth).obs;
  final month = _firstOfMonth(DateTime.now()).obs;
  final state = const ResourceState<ReportData>.idle().obs;

  static DateTime _firstOfMonth(DateTime value) =>
      DateTime(value.year, value.month);

  /// Rentang satu bulan kalender; bulan berjalan berakhir hari ini.
  static DateRange monthRange(DateTime month, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final start = _firstOfMonth(month);
    final last = DateTime(start.year, start.month + 1, 0);
    final isCurrent = start.year == today.year && start.month == today.month;
    return DateRange(
      start: start,
      end: isCurrent ? DateTime(today.year, today.month, today.day) : last,
    );
  }

  /// Rentang bulan sebelumnya dengan jumlah hari yang sama dengan [current],
  /// supaya bulan berjalan dibandingkan dengan hari yang setara.
  static DateRange previousMonthRange(DateRange current) {
    final start = DateTime(current.start.year, current.start.month - 1);
    final last = DateTime(start.year, start.month + 1, 0);
    final endDay = current.end.day < last.day ? current.end.day : last.day;
    return DateRange(
      start: start,
      end: DateTime(start.year, start.month, endDay),
    );
  }

  Future<void> loadMonth(DateTime selectedMonth) {
    month.value = _firstOfMonth(selectedMonth);
    final selected = monthRange(month.value);
    return load(selected, previousRange: previousMonthRange(selected));
  }

  Future<void> reload() => loadMonth(month.value);

  Future<void> load(DateRange selectedRange, {DateRange? previousRange}) async {
    range.value = selectedRange;
    state.value = const ResourceState.loading();
    try {
      // Hanya periode terpilih dan pembandingnya yang dibaca dari database.
      final comparison =
          previousRange ?? selectedRange.previousEquivalentPeriod;
      final transactions = await _transactions.getAll(
        range: DateRange(
          start: comparison.start.isBefore(selectedRange.start)
              ? comparison.start
              : selectedRange.start,
          end: comparison.end.isAfter(selectedRange.end)
              ? comparison.end
              : selectedRange.end,
        ),
      );
      final isEmpty = !transactions.any(
        (transaction) => selectedRange.contains(transaction.transactionDate),
      );

      final categories = await _categories.getAll(includeArchived: true);
      final categoriesById = {
        for (final category in categories)
          if (category.id != null) category.id!: category,
      };
      final totals = _calculations.categoryTotals(transactions, selectedRange);
      final expensesByCategory = totals.entries.map((entry) {
        final category = categoriesById[entry.key];
        return ReportCategoryTotal(
          categoryId: entry.key,
          name: category?.name ?? 'Kategori diarsipkan'.tr,
          colorValue: category?.colorValue ?? 0xFF64748B,
          amount: entry.value,
        );
      }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

      final highDay = _calculations.highestSpendingDay(
        transactions,
        selectedRange,
      );
      final highDayAmount = highDay == null
          ? 0
          : _calculations.expenseOnDay(transactions, highDay);
      final merchant = _calculations.topMerchant(transactions, selectedRange);
      final summary = _calculations.summary(transactions, selectedRange);
      final previousExpense = _calculations
          .summary(
            transactions,
            previousRange ?? selectedRange.previousEquivalentPeriod,
          )
          .expense;
      final dailyByDate = {
        for (final point in _calculations.dailyExpenses(
          transactions,
          selectedRange,
        ))
          point.date: point.amount,
      };
      final dailySpending = [
        for (var i = 0; i < selectedRange.dayCount; i++)
          dailyByDate[DateTime(
                selectedRange.start.year,
                selectedRange.start.month,
                selectedRange.start.day + i,
              )] ??
              0,
      ];

      state.value = ResourceState.success(
        ReportData(
          summary: summary,
          expensesByCategory: expensesByCategory,
          expenseChange: previousExpense == 0
              ? (summary.expense == 0 ? 0 : 1)
              : (summary.expense - previousExpense) / previousExpense,
          previousExpense: previousExpense,
          incomeTrend: const MonthlyTrendService().build(
            transactions,
            DateTime(selectedRange.start.year, selectedRange.start.month),
            type: TransactionType.income,
          ),
          isEmpty: isEmpty,
          dailySpending: dailySpending,
          dailyAverage: _calculations.dailyAverage(transactions, selectedRange),
          highestSpendingDay: highDay,
          highestSpendingDayAmount: highDayAmount,
          topMerchant: merchant?.key,
          topMerchantCount: merchant?.value ?? 0,
        ),
      );
    } catch (_) {
      state.value = ResourceState.error('Gagal memuat laporan.'.tr);
    }
  }
}
