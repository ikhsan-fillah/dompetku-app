/// Kartu ringkas satu kategori pengeluaran di Beranda.
class CategoryCardData {
  const CategoryCardData({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.amount,
    required this.sharePercent,
  });

  final int categoryId;
  final String name;
  final String iconKey;
  final int colorValue;
  final int amount;
  final double sharePercent;
}

class RecentTransactionItem {
  const RecentTransactionItem({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.iconKey,
    required this.colorValue,
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  final int id;
  final String title;
  final String categoryName;
  final String iconKey;
  final int colorValue;
  final int amount;
  final bool isIncome;
  final DateTime date;
}

class DashboardInsight {
  const DashboardInsight({required this.message});

  final String message;
}
