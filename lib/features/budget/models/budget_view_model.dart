import '../../../core/utils/budget_status.dart';
import 'budget_model.dart';

/// Model siap-tampil untuk daftar anggaran.
class BudgetViewModel {
  const BudgetViewModel({required this.budget, required this.used});

  final BudgetModel budget;
  final int used;

  int get remaining => budget.amountLimit - used;

  double get percent =>
      BudgetStatus.percentUsed(used: used, limit: budget.amountLimit);

  BudgetLevel get level => BudgetStatus.levelFor(percent);

  bool get isOverall => budget.categoryId == null;

  /// Judul baris dan keterangan kategori tanpa nama yang tampil dua kali.
  ///
  /// Nama bawaan seperti "Anggaran Makanan" sama dengan kategorinya, jadi cukup
  /// satu judul: nama kategori. Nama buatan sendiri (mis. "makan") tetap jadi
  /// judul dan kategorinya (mis. "Makanan & Minuman") tampil sebagai keterangan.
  ({String title, String? category}) labelsFor(String? categoryName) {
    final name = budget.name.trim();
    final category = categoryName?.trim();
    if (category == null || category.isEmpty) {
      return (title: name, category: null);
    }
    var bare = name;
    for (final prefix in const ['Anggaran ', 'Budget ']) {
      if (name.toLowerCase().startsWith(prefix.toLowerCase())) {
        bare = name.substring(prefix.length).trim();
        break;
      }
    }
    if (bare.toLowerCase() == category.toLowerCase()) {
      return (title: category, category: null);
    }
    return (title: name, category: category);
  }
}
