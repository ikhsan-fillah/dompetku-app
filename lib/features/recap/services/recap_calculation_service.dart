import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';
import '../../budget/models/budget_model.dart';
import '../../dashboard/services/financial_calculation_service.dart';
import '../../transaction/models/transaction_model.dart';

class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.total,
    required this.count,
  });

  final int categoryId;
  final int total;
  final int count;
}

class MerchantSpend {
  const MerchantSpend({
    required this.name,
    required this.visits,
    required this.total,
  });

  final String name;
  final int visits;
  final int total;
}

class BiggestExpense {
  const BiggestExpense({
    required this.name,
    required this.amount,
    required this.date,
  });

  final String name;
  final int amount;
  final DateTime date;
}

class BudgetSpend {
  const BudgetSpend({required this.budget, required this.used});

  final BudgetModel budget;
  final int used;

  double get percent =>
      budget.amountLimit <= 0 ? 0 : used * 100 / budget.amountLimit;
}

enum BudgetMonthStatus { noData, inside, over }

class MonthlyRecap {
  const MonthlyRecap({
    required this.year,
    required this.month,
    required this.spent,
    required this.income,
    required this.daysInMonth,
    required this.elapsedDays,
    required this.isSoFar,
    required this.topCategories,
    required this.transactionCount,
    required this.dailySpend,
    required this.previousSpent,
    required this.merchants,
    required this.budgets,
    required this.overallBudget,
  });

  final int year;
  final int month;
  final int spent;
  final int income;
  final int daysInMonth;
  final int elapsedDays;
  final bool isSoFar;
  final List<CategorySpend> topCategories;
  final int transactionCount;
  final List<int> dailySpend;
  final int? previousSpent;
  final List<MerchantSpend> merchants;
  final List<BudgetSpend> budgets;
  final int overallBudget;

  int get net => income - spent;
  bool get hasData => transactionCount > 0;
  int get dailyAverage => elapsedDays == 0 ? 0 : spent ~/ elapsedDays;
  int get noSpendDays =>
      dailySpend.take(elapsedDays).where((value) => value == 0).length;

  int? get heaviestDay {
    var index = -1;
    for (var i = 0; i < elapsedDays; i++) {
      if (dailySpend[i] > 0 &&
          (index < 0 || dailySpend[i] > dailySpend[index])) {
        index = i;
      }
    }
    return index < 0 ? null : index + 1;
  }

  /// Batas harian = total budget keseluruhan dibagi jumlah hari. Null bila tidak ada.
  int? get dailyLimit =>
      overallBudget <= 0 ? null : overallBudget ~/ daysInMonth;

  int get daysUnderLimit {
    final limit = dailyLimit;
    if (limit == null) return 0;
    return dailySpend.take(elapsedDays).where((value) => value <= limit).length;
  }

  BudgetMonthStatus get budgetStatus {
    if (!hasData || overallBudget == 0) return BudgetMonthStatus.noData;
    return spent <= overallBudget
        ? BudgetMonthStatus.inside
        : BudgetMonthStatus.over;
  }
}

class YearlyRecap {
  const YearlyRecap({
    required this.year,
    required this.totalSpent,
    required this.totalIncome,
    required this.activeMonths,
    required this.monthsSoFar,
    required this.heaviestMonth,
    required this.lightestMonth,
    required this.months,
    required this.topCategories,
    required this.topMerchant,
    required this.quietStreak,
    required this.quietDays,
    required this.biggestExpense,
  });

  final int year;
  final int quietStreak;
  final int quietDays;
  final BiggestExpense? biggestExpense;
  final int totalSpent;
  final int totalIncome;
  final int activeMonths;
  final int monthsSoFar;
  final int? heaviestMonth;
  final int? lightestMonth;
  final List<MonthlyRecap> months;
  final List<CategorySpend> topCategories;
  final MerchantSpend? topMerchant;

  int get net => totalIncome - totalSpent;
  bool get isSoFar => monthsSoFar < 12;
  int get budgetMonthsWithData =>
      months.where((m) => m.budgetStatus != BudgetMonthStatus.noData).length;
  int get budgetMonthsInside =>
      months.where((m) => m.budgetStatus == BudgetMonthStatus.inside).length;
}

/// Semua angka recap. Memakai [FinancialCalculationService] yang sama dengan
/// Beranda agar angka untuk periode yang sama tidak berbeda.
class RecapCalculationService {
  const RecapCalculationService(this._finance);

  final FinancialCalculationService _finance;

  MonthlyRecap monthly(
    Iterable<TransactionModel> transactions, {
    required int year,
    required int month,
    required DateTime now,
    Iterable<BudgetModel> budgets = const [],
  }) {
    final list = transactions.toList();
    final range = _monthRange(year, month);
    final spent = _finance.totalForType(list, TransactionType.expense, range);
    final income = _finance.totalForType(list, TransactionType.income, range);
    final inMonth = list
        .where((t) => range.contains(t.transactionDate))
        .toList();
    final expenses = inMonth
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final daysInMonth = range.end.day;

    final daily = List<int>.filled(daysInMonth, 0);
    for (final point in _finance.dailyExpenses(list, range)) {
      daily[point.date.day - 1] = point.amount;
    }

    final previousRange = month == 1
        ? _monthRange(year - 1, 12)
        : _monthRange(year, month - 1);
    final previousHasData = list.any(
      (t) => previousRange.contains(t.transactionDate),
    );
    final previousSpent = previousHasData
        ? _finance.totalForType(list, TransactionType.expense, previousRange)
        : null;

    final activeBudgets = budgets
        .where((budget) => _overlaps(budget, range))
        .toList();

    return MonthlyRecap(
      year: year,
      month: month,
      spent: spent,
      income: income,
      daysInMonth: daysInMonth,
      elapsedDays: _elapsedDays(year, month, daysInMonth, now),
      isSoFar: now.year == year && now.month == month,
      topCategories: _categories(expenses),
      transactionCount: inMonth.length,
      dailySpend: daily,
      previousSpent: previousSpent,
      merchants: _merchants(expenses),
      budgets: [
        for (final budget in activeBudgets)
          BudgetSpend(
            budget: budget,
            used: _budgetUsed(budget, expenses, range),
          ),
      ],
      overallBudget: activeBudgets
          .where((budget) => budget.categoryId == null)
          .fold(0, (total, budget) => total + budget.amountLimit),
    );
  }

  YearlyRecap yearly(
    Iterable<TransactionModel> transactions, {
    required int year,
    required DateTime now,
    Iterable<BudgetModel> budgets = const [],
  }) {
    final list = transactions.toList();
    final budgetList = budgets.toList();
    final months = [
      for (var m = 1; m <= 12; m++)
        monthly(list, year: year, month: m, now: now, budgets: budgetList),
    ];
    final yearRange = DateRange(
      start: DateTime(year),
      end: DateTime(year, 12, 31),
    );
    final yearExpenses = list
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              yearRange.contains(t.transactionDate),
        )
        .toList();
    final merchants = _merchants(yearExpenses);
    final quiet = _quietDays(
      list.where((t) => yearRange.contains(t.transactionDate)).toList(),
      year,
      now,
    );

    MonthlyRecap? heaviest;
    MonthlyRecap? lightest;
    for (final recap in months.where((m) => m.hasData)) {
      if (heaviest == null || recap.spent > heaviest.spent) heaviest = recap;
      if (lightest == null || recap.spent < lightest.spent) lightest = recap;
    }

    return YearlyRecap(
      year: year,
      totalSpent: months.fold(0, (total, m) => total + m.spent),
      totalIncome: months.fold(0, (total, m) => total + m.income),
      activeMonths: months.where((m) => m.hasData).length,
      monthsSoFar: year < now.year ? 12 : (year == now.year ? now.month : 0),
      heaviestMonth: heaviest?.month,
      lightestMonth: lightest?.month,
      months: months,
      topCategories: _categories(yearExpenses).take(5).toList(),
      topMerchant: merchants.isEmpty ? null : merchants.first,
      quietStreak: quiet.longest,
      quietDays: quiet.total,
      biggestExpense: _biggest(yearExpenses),
    );
  }

  BiggestExpense? _biggest(List<TransactionModel> expenses) {
    if (expenses.isEmpty) return null;
    final top = expenses.reduce((a, b) => b.amount > a.amount ? b : a);
    final merchant = top.merchantOrSource?.trim();
    return BiggestExpense(
      name: (merchant == null || merchant.isEmpty) ? top.title : merchant,
      amount: top.amount,
      date: top.transactionDate,
    );
  }

  /// Hari tanpa pengeluaran dihitung sejak transaksi pertama tercatat di tahun
  /// itu sampai hari terakhir periode (hari ini bila tahun berjalan).
  ({int longest, int total}) _quietDays(
    List<TransactionModel> yearTransactions,
    int year,
    DateTime now,
  ) {
    if (yearTransactions.isEmpty) return (longest: 0, total: 0);
    DateTime day(DateTime v) => DateTime(v.year, v.month, v.day);
    final first = yearTransactions
        .map((t) => day(t.transactionDate.toLocal()))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final today = day(now);
    final yearEnd = DateTime(year, 12, 31);
    final end = today.isBefore(yearEnd) ? today : yearEnd;
    if (first.isAfter(end)) return (longest: 0, total: 0);

    final spendDays = {
      for (final t in yearTransactions)
        if (t.type == TransactionType.expense) day(t.transactionDate.toLocal()),
    };
    var longest = 0;
    var current = 0;
    var total = 0;
    for (
      var d = first;
      !d.isAfter(end);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      if (spendDays.contains(d)) {
        current = 0;
      } else {
        current++;
        total++;
        if (current > longest) longest = current;
      }
    }
    return (longest: longest, total: total);
  }

  DateRange _monthRange(int year, int month) => DateRange(
    start: DateTime(year, month, 1),
    end: DateTime(year, month + 1, 0),
  );

  int _elapsedDays(int year, int month, int daysInMonth, DateTime now) {
    if (year > now.year || (year == now.year && month > now.month)) return 0;
    if (year == now.year && month == now.month) return now.day;
    return daysInMonth;
  }

  bool _overlaps(BudgetModel budget, DateRange range) {
    final budgetRange = DateRange(start: budget.startDate, end: budget.endDate);
    return !budgetRange.start.isAfter(range.end) &&
        !budgetRange.end.isBefore(range.start);
  }

  int _budgetUsed(
    BudgetModel budget,
    List<TransactionModel> expenses,
    DateRange month,
  ) {
    final budgetRange = DateRange(start: budget.startDate, end: budget.endDate);
    final start = budgetRange.start.isAfter(month.start)
        ? budgetRange.start
        : month.start;
    final end = budgetRange.end.isBefore(month.end)
        ? budgetRange.end
        : month.end;
    if (start.isAfter(end)) return 0;
    final scoped = budget.categoryId == null
        ? expenses
        : expenses.where((t) => t.categoryId == budget.categoryId).toList();
    return _finance.totalForType(
      scoped,
      TransactionType.expense,
      DateRange(start: start, end: end),
    );
  }

  List<CategorySpend> _categories(List<TransactionModel> expenses) {
    final byCategory = <int, List<int>>{};
    for (final tx in expenses) {
      final bucket = byCategory.putIfAbsent(tx.categoryId, () => [0, 0]);
      bucket[0] += tx.amount;
      bucket[1] += 1;
    }
    return byCategory.entries
        .map(
          (e) => CategorySpend(
            categoryId: e.key,
            total: e.value[0],
            count: e.value[1],
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  List<MerchantSpend> _merchants(List<TransactionModel> expenses) {
    final byName = <String, List<int>>{};
    for (final tx in expenses) {
      final merchant = tx.merchantOrSource?.trim();
      final name = (merchant == null || merchant.isEmpty)
          ? tx.title.trim()
          : merchant;
      if (name.isEmpty) continue;
      final bucket = byName.putIfAbsent(name, () => [0, 0]);
      bucket[0] += 1;
      bucket[1] += tx.amount;
    }
    return byName.entries
        .map(
          (e) =>
              MerchantSpend(name: e.key, visits: e.value[0], total: e.value[1]),
        )
        .toList()
      ..sort((a, b) {
        final visits = b.visits.compareTo(a.visits);
        return visits != 0 ? visits : b.total.compareTo(a.total);
      });
  }
}
