import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../budget/repositories/budget_repository.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';
import '../services/category_detail_service.dart';

class CategoryDetailController extends GetxController {
  CategoryDetailController(
    this._transactions,
    this._categories,
    this._budgets,
  );

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final BudgetRepository _budgets;
  final state = const ResourceState<CategoryDetailData>.idle().obs;
  final range = DateRange.fromPreset(DateRangePreset.month).obs;
  final _service = const CategoryDetailService();

  late final int categoryId;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, Object?>? ?? const {};
    categoryId = arguments['categoryId'] as int;
    final selectedRange = arguments['range'];
    if (selectedRange is DateRange) range.value = selectedRange;
    load();
  }

  Future<void> load({DateRange? selectedRange}) async {
    if (selectedRange != null) range.value = selectedRange;
    state.value = const ResourceState.loading();
    try {
      final results = await Future.wait([
        _transactions.getAll(),
        _categories.getAll(includeArchived: true),
        _budgets.getAll(),
      ]);
      final transactions = results[0] as List;
      final categories = results[1] as List<CategoryModel>;
      final budgets = results[2] as List;
      state.value = ResourceState.success(
        _service.build(
          categoryId: categoryId,
          range: range.value,
          transactions: transactions.cast(),
          categories: categories,
          budgets: budgets.cast(),
        ),
      );
    } catch (_) {
      state.value = const ResourceState.error('Gagal memuat detail kategori.');
    }
  }
}