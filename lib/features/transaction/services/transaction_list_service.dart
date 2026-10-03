import '../../../core/constant/domain_enums.dart';
import '../../category/models/category_model.dart';
import '../../dashboard/models/dashboard_view_models.dart';
import '../models/transaction_model.dart';

enum TransactionTypeFilter { all, expense, income }

enum TransactionSort {
  terbaru,
  terlama,
  nominalTerbesar,
  nominalTerkecil,
  namaAZ,
  namaZA,
  kategoriAZ,
}

class TransactionDayGroup {
  const TransactionDayGroup({required this.date, required this.items});

  final DateTime date;
  final List<RecentTransactionItem> items;
}

class TransactionListResult {
  const TransactionListResult({
    required this.groups,
    required this.items,
    required this.income,
    required this.expense,
  });

  final List<TransactionDayGroup> groups;
  final List<RecentTransactionItem> items;
  final int income;
  final int expense;

  bool get isEmpty => groups.isEmpty && items.isEmpty;

  bool get isGrouped => groups.isNotEmpty && items.isEmpty;
}

/// Menyusun daftar transaksi: filter jenis, pencarian, dan pengelompokan per hari.
class TransactionListService {
  const TransactionListService();

  TransactionListResult build({
    required Iterable<TransactionModel> transactions,
    required List<CategoryModel> categories,
    TransactionTypeFilter filter = TransactionTypeFilter.all,
    String query = '',
    TransactionSort sort = TransactionSort.terbaru,
  }) {
    final byId = {
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };
    final needle = query.trim().toLowerCase();

    final selected = transactions.where((item) {
      final typeOk = switch (filter) {
        TransactionTypeFilter.all => true,
        TransactionTypeFilter.expense => item.type == TransactionType.expense,
        TransactionTypeFilter.income => item.type == TransactionType.income,
      };
      if (!typeOk) return false;
      if (needle.isEmpty) return true;
      final haystack = [
        item.title,
        item.note ?? '',
        item.merchantOrSource ?? '',
        byId[item.categoryId]?.name ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList()..sort((a, b) => _compare(a, b, sort, byId));

    var income = 0;
    var expense = 0;
    final flat = <RecentTransactionItem>[];
    final groups = <DateTime, List<RecentTransactionItem>>{};
    for (final item in selected) {
      if (item.type == TransactionType.income) {
        income += item.amount;
      } else {
        expense += item.amount;
      }
      final local = item.transactionDate.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final category = byId[item.categoryId];
      final view = RecentTransactionItem(
        id: item.id ?? 0,
        title: item.title,
        categoryName: category?.name ?? 'Tanpa kategori',
        iconKey: category?.iconKey ?? 'more_horiz',
        colorValue: category?.colorValue ?? 0xFF90A4AE,
        amount: item.amount,
        isIncome: item.type == TransactionType.income,
        date: local,
      );
      if (sort == TransactionSort.terbaru || sort == TransactionSort.terlama) {
        groups.putIfAbsent(day, () => []).add(view);
      } else {
        flat.add(view);
      }
    }
    return TransactionListResult(
      groups: [
        for (final entry in groups.entries)
          TransactionDayGroup(date: entry.key, items: entry.value),
      ],
      items: flat,
      income: income,
      expense: expense,
    );
  }

  int _compare(
    TransactionModel a,
    TransactionModel b,
    TransactionSort sort,
    Map<int, CategoryModel> categories,
  ) {
    int byDate() {
      final value = b.transactionDate.compareTo(a.transactionDate);
      return value != 0 ? value : (b.id ?? 0).compareTo(a.id ?? 0);
    }

    int byId() => (b.id ?? 0).compareTo(a.id ?? 0);
    int byName() => a.title.toLowerCase().compareTo(b.title.toLowerCase());
    int byCategory() => (categories[a.categoryId]?.name ?? 'Tanpa kategori')
        .toLowerCase()
        .compareTo(
          (categories[b.categoryId]?.name ?? 'Tanpa kategori').toLowerCase(),
        );

    final value = switch (sort) {
      TransactionSort.terbaru => byDate(),
      TransactionSort.terlama => -byDate(),
      TransactionSort.nominalTerbesar => b.amount.compareTo(a.amount),
      TransactionSort.nominalTerkecil => a.amount.compareTo(b.amount),
      TransactionSort.namaAZ => byName(),
      TransactionSort.namaZA => -byName(),
      TransactionSort.kategoriAZ => byCategory(),
    };
    if (value != 0) return value;
    final date = b.transactionDate.compareTo(a.transactionDate);
    return date != 0 ? date : byId();
  }
}
