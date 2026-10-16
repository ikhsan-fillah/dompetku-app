import 'package:get/get.dart';

import '../../budget/models/budget_model.dart';
import '../../budget/repositories/budget_repository.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';

class RecapData {
  const RecapData({
    required this.transactions,
    required this.budgets,
    required this.categories,
  });

  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets;
  final Map<int, CategoryModel> categories;

  String categoryName(int id) => categories[id]?.name ?? 'Other';
}

Future<RecapData> loadRecapData() async {
  final results = await Future.wait([
    Get.find<TransactionRepository>().getAll(),
    Get.find<BudgetRepository>().getAll(),
    Get.find<CategoryRepository>().getAll(includeArchived: true),
  ]);
  final categories = results[2] as List<CategoryModel>;
  return RecapData(
    transactions: results[0] as List<TransactionModel>,
    budgets: results[1] as List<BudgetModel>,
    categories: {
      for (final category in categories)
        if (category.id != null) category.id!: category,
    },
  );
}
