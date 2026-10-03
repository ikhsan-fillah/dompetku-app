import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../services/category_detail_service.dart';

class CategoryDetailController extends GetxController {
  CategoryDetailController(this._transactions, this._categories);

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final state = const ResourceState<List<TransactionModel>>.idle().obs;
  final summary = Rxn<CategoryTransactionSummary>();
  final category = Rxn<CategoryModel>();
  final range = DateRange.fromPreset(DateRangePreset.currentMonth).obs;
  final sort = CategoryTransactionSort.newest.obs;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;
  final _service = const CategoryDetailService();
  static const pageSize = 30;
  late final int categoryId;
  int _loadedCount = 0;
  int _requestId = 0;
  Worker? _refreshWorker;

  TransactionPageRepository get _pageRepository =>
      _transactions as TransactionPageRepository;

  List<TransactionDayGroup> get groups => _service.group(
    state.value.data ?? const <TransactionModel>[],
    sort.value,
  );

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, Object?>? ?? const {};
    categoryId = arguments['categoryId'] as int;
    final selectedRange = arguments['range'];
    if (selectedRange is DateRange) {
      DateRange.validateHistory(selectedRange);
      range.value = selectedRange;
    }
    if (Get.isRegistered<DataRefreshService>()) {
      _refreshWorker = ever<int>(
        Get.find<DataRefreshService>().version,
        (_) => load(silent: true),
      );
    }
    load();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    super.onClose();
  }

  void setSort(CategoryTransactionSort value) {
    if (sort.value == value) return;
    sort.value = value;
    load(silent: true);
  }

  Future<void> load({DateRange? selectedRange, bool silent = false}) async {
    if (selectedRange != null) {
      DateRange.validateHistory(selectedRange);
      range.value = selectedRange;
    }
    final requestId = ++_requestId;
    if (!silent || state.value.status != ResourceStatus.success) {
      state.value = const ResourceState.loading();
    }
    try {
      final results = await Future.wait([
        _pageRepository.getPage(
          TransactionPageRequest(
            categoryId: categoryId,
            range: range.value,
            dateSort: sort.value == CategoryTransactionSort.newest
                ? TransactionDateSort.newest
                : TransactionDateSort.oldest,
            limit: pageSize,
          ),
        ),
        _pageRepository.getCategorySummary(
          categoryId: categoryId,
          range: range.value,
        ),
        _categories.getAll(includeArchived: true),
      ]);
      if (requestId != _requestId) return;
      final page = results[0] as List<TransactionModel>;
      _loadedCount = page.length;
      hasMore.value = page.length == pageSize;
      summary.value = results[1] as CategoryTransactionSummary;
      category.value = (results[2] as List<CategoryModel>)
          .where((item) => item.id == categoryId)
          .firstOrNull;
      state.value = page.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(page);
    } catch (_) {
      if (requestId == _requestId) {
        state.value = const ResourceState.error(
          'Gagal memuat transaksi kategori.',
        );
      }
    }
  }

  Future<void> loadNextPage() async {
    if (!hasMore.value ||
        isLoadingMore.value ||
        state.value.status != ResourceStatus.success) {
      return;
    }
    isLoadingMore.value = true;
    try {
      final page = await _pageRepository.getPage(
        TransactionPageRequest(
          categoryId: categoryId,
          range: range.value,
          dateSort: sort.value == CategoryTransactionSort.newest
              ? TransactionDateSort.newest
              : TransactionDateSort.oldest,
          limit: pageSize,
          offset: _loadedCount,
        ),
      );
      final current = state.value.data ?? const <TransactionModel>[];
      state.value = ResourceState.success([...current, ...page]);
      _loadedCount += page.length;
      hasMore.value = page.length == pageSize;
    } finally {
      isLoadingMore.value = false;
    }
  }
}
