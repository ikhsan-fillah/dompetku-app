import '../../../core/constant/domain_enums.dart';
import '../../category/models/category_model.dart';
import '../../dashboard/models/dashboard_view_models.dart';
import '../models/transaction_model.dart';

enum TransactionTypeFilter { all, expense, income }

class TransactionDayGroup {
  const TransactionDayGroup({required this.date, required this.items});

  final DateTime date;
  final List<RecentTransactionItem> items;
}

class TransactionListResult {
  const TransactionListResult({
    required this.groups,
    required this.income,
    required this.expense,
  });

  final List<TransactionDayGroup> groups;
  final int income;
  final int expense;

  bool get isEmpty => groups.isEmpty;
}

/// Menyusun daftar transaksi: filter jenis, pencarian, dan pengelompokan per hari.
class TransactionListService {
  const TransactionListService();

  TransactionListResult build({
    required Iterable<TransactionModel> transactions,
    required List<CategoryModel> categories,
    TransactionTypeFilter filter = TransactionTypeFilter.all,
    String query = '',
  }) {
    final byId = {
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };
    final needle = query.trim().toLowerCase();

    final selected =
        transactions.where((item) {
          final typeOk = switch (filter) {
            TransactionTypeFilter.all => true,
            TransactionTypeFilter.expense =>
              item.type == TransactionType.expense,
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
        }).toList()..sort((a, b) {
          final byDate = b.transactionDate.compareTo(a.transactionDate);
          return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
        });

    var income = 0;
    var expense = 0;
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
      groups
          .putIfAbsent(day, () => [])
          .add(
            RecentTransactionItem(
              id: item.id ?? 0,
              title: item.title,
              categoryName: category?.name ?? 'Tanpa kategori',
              iconKey: category?.iconKey ?? 'more_horiz',
              colorValue: category?.colorValue ?? 0xFF90A4AE,
              amount: item.amount,
              isIncome: item.type == TransactionType.income,
              date: local,
            ),
          );
    }
    return TransactionListResult(
      groups: [
        for (final entry in groups.entries)
          TransactionDayGroup(date: entry.key, items: entry.value),
      ],
      income: income,
      expense: expense,
    );
  }
}
