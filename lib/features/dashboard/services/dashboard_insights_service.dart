import 'dart:math' as math;

import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';
import '../../category/models/category_model.dart';
import '../../transaction/models/transaction_model.dart';
import '../models/dashboard_view_models.dart';
import '../models/spending_trend_point.dart';

/// Perhitungan murni untuk kartu-kartu Beranda.
class DashboardInsightsService {
  const DashboardInsightsService();

  List<CategoryCardData> zeroStateCards(
    List<CategoryModel> categories, {
    int limit = 4,
  }) {
    final active = categories
        .where(
          (category) =>
              category.id != null &&
              !category.isArchived &&
              category.type == TransactionType.expense,
        )
        .toList();
    final chosen = <CategoryModel>[
      ...active.where((category) => category.isFavorite),
      ...active.where((category) => !category.isFavorite),
    ];
    chosen.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    const fallback = [
      (-1, 'Food and drinks', 'restaurant', 0xFFE57373),
      (-2, 'Transportation', 'directions_car', 0xFF64B5F6),
      (-3, 'Shopping', 'shopping_bag', 0xFFBA68C8),
      (-4, 'Bills', 'receipt_long', 0xFFFFB74D),
    ];
    final result = <CategoryCardData>[];
    for (final category in chosen.take(limit)) {
      result.add(
        CategoryCardData(
          categoryId: category.id!,
          name: category.name,
          iconKey: category.iconKey,
          colorValue: category.colorValue,
          amount: 0,
          sharePercent: 0,
        ),
      );
    }
    for (final item in fallback) {
      if (result.length >= limit) break;
      if (result.any((card) => card.name == item.$2)) continue;
      result.add(
        CategoryCardData(
          categoryId: item.$1,
          name: item.$2,
          iconKey: item.$3,
          colorValue: item.$4,
          amount: 0,
          sharePercent: 0,
        ),
      );
    }
    return result;
  }

  /// Kategori favorit lebih dulu, sisanya diisi kategori dengan pengeluaran terbesar.
  List<CategoryCardData> favoriteCards({
    required Map<int, int> totals,
    required List<CategoryModel> categories,
    int limit = 4,
  }) {
    final expenseTotal = totals.values.fold<int>(0, (a, b) => a + b);
    final active = categories
        .where(
          (c) =>
              c.id != null &&
              !c.isArchived &&
              c.type == TransactionType.expense,
        )
        .toList();
    final chosen = active.where((c) => c.isFavorite).take(limit).toList();
    if (chosen.length < limit) {
      final rest = active.where((c) => !chosen.contains(c)).toList()
        ..sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));
      for (final category in rest) {
        if (chosen.length >= limit) break;
        if ((totals[category.id] ?? 0) > 0) chosen.add(category);
      }
    }
    return [
      for (final category in chosen)
        CategoryCardData(
          categoryId: category.id!,
          name: category.name,
          iconKey: category.iconKey,
          colorValue: category.colorValue,
          amount: totals[category.id] ?? 0,
          sharePercent: expenseTotal == 0
              ? 0
              : (totals[category.id] ?? 0) * 100 / expenseTotal,
        ),
    ];
  }

  List<RecentTransactionItem> recentTransactions({
    required Iterable<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required DateRange range,
    int limit = 4,
  }) {
    final byId = {
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };
    final inRange =
        transactions
            .where((item) => range.contains(item.transactionDate))
            .toList()
          ..sort((a, b) {
            final byDate = b.transactionDate.compareTo(a.transactionDate);
            return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
          });
    return [
      for (final item in inRange.take(limit))
        RecentTransactionItem(
          id: item.id ?? 0,
          title: item.title,
          categoryName: byId[item.categoryId]?.name ?? 'Tanpa kategori',
          iconKey: byId[item.categoryId]?.iconKey ?? 'more_horiz',
          colorValue: byId[item.categoryId]?.colorValue ?? 0xFF90A4AE,
          amount: item.amount,
          isIncome: item.type == TransactionType.income,
          date: item.transactionDate.toLocal(),
        ),
    ];
  }

  /// Insight netral: kategori dengan kenaikan terbesar dibanding periode sebelumnya.
  DashboardInsight? spendingInsight({
    required Map<int, int> current,
    required Map<int, int> previous,
    required List<CategoryModel> categories,
    double minimumChange = 0.10,
  }) {
    int? bestId;
    var bestChange = 0.0;
    for (final entry in current.entries) {
      final before = previous[entry.key] ?? 0;
      if (before <= 0 || entry.value <= before) continue;
      final change = (entry.value - before) / before;
      if (change >= minimumChange && (bestId == null || change > bestChange)) {
        bestId = entry.key;
        bestChange = change;
      }
    }
    final id = bestId;
    if (id == null) return null;
    var name = 'Sebuah kategori';
    for (final category in categories) {
      if (category.id == id) name = category.name;
    }
    return DashboardInsight(
      message:
          '$name naik ${(bestChange * 100).round()}% dibanding periode sebelumnya',
    );
  }

  /// Mengelompokkan pengeluaran harian menjadi paling banyak [maxBars] batang.
  List<TrendBucket> trendBuckets({
    required List<SpendingTrendPoint> points,
    required DateRange range,
    int maxBars = 15,
  }) {
    if (points.isEmpty) return const [];
    final amounts = {
      for (final point in points)
        DateTime(point.date.year, point.date.month, point.date.day):
            point.amount,
    };
    final first = points.first.date;
    final start = range.dayCount <= 400
        ? range.start
        : DateTime(first.year, first.month, first.day);
    final totalDays = _daysBetween(start, range.end) + 1;
    if (totalDays <= 0) return const [];
    final size = math.max(1, (totalDays / maxBars).ceil());
    final buckets = <TrendBucket>[];
    for (var offset = 0; offset < totalDays; offset += size) {
      final last = math.min(offset + size - 1, totalDays - 1);
      final bucketStart = DateTime(start.year, start.month, start.day + offset);
      final bucketEnd = DateTime(start.year, start.month, start.day + last);
      var sum = 0;
      for (var day = offset; day <= last; day++) {
        sum += amounts[DateTime(start.year, start.month, start.day + day)] ?? 0;
      }
      buckets.add(
        TrendBucket(
          label: totalDays <= 31
              ? '${bucketStart.day}'
              : '${bucketStart.day}/${bucketStart.month}',
          start: bucketStart,
          end: bucketEnd,
          amount: sum,
        ),
      );
    }
    return buckets;
  }

  int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
