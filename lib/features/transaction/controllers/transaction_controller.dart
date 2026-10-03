import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/validator.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../services/transaction_list_service.dart';

class TransactionController extends GetxController {
  TransactionController(this._repository, {CategoryRepository? categories})
    : _categories = categories;

  final TransactionRepository _repository;
  final CategoryRepository? _categories;
  final _listService = const TransactionListService();

  final range = Rxn<DateRange>();
  final state = const ResourceState<List<TransactionModel>>.idle().obs;
  final categories = <CategoryModel>[].obs;
  final filter = TransactionTypeFilter.all.obs;
  final sort = TransactionSort.terbaru.obs;
  final query = ''.obs;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;

  static const pageSize = 25;
  Timer? _queryDebounce;
  int _loadedCount = 0;

  Worker? _refreshWorker;
  int _requestId = 0;

  CategoryRepository? get _categoryRepository =>
      _categories ??
      (Get.isRegistered<CategoryRepository>()
          ? Get.find<CategoryRepository>()
          : null);

  TransactionPageRepository? get _pageRepository =>
      _repository is TransactionPageRepository
          ? _repository as TransactionPageRepository
          : null;

  /// Daftar yang sudah difilter, dicari, dan dikelompokkan per hari.
  TransactionListResult get list => _listService.build(
    transactions: state.value.data ?? const <TransactionModel>[],
    categories: categories.toList(),
    filter: filter.value,
    query: query.value,
    sort: sort.value,
  );

  @override
  void onInit() {
    super.onInit();
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
    _queryDebounce?.cancel();
    super.onClose();
  }

  void setFilter(TransactionTypeFilter value) {
    if (filter.value == value) return;
    filter.value = value;
    _resetPagedLoad();
  }

  void setSort(TransactionSort value) {
    if (sort.value == value) return;
    sort.value = value;
    _resetPagedLoad();
  }

  void setQuery(String value) {
    query.value = value;
    if (_pageRepository == null) return;
    _queryDebounce?.cancel();
    _queryDebounce = Timer(const Duration(milliseconds: 300), () {
      load();
    });
  }

  TransactionModel? findById(int id) {
    for (final item in state.value.data ?? const <TransactionModel>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> load({DateRange? selectedRange, bool silent = false}) async {
    if (selectedRange != null) range.value = selectedRange;
    final requestId = ++_requestId;
    if (!silent || state.value.status != ResourceStatus.success) {
      state.value = const ResourceState.loading();
    }
    try {
      final pageRepository = _pageRepository;
      if (pageRepository != null) {
        final page = await pageRepository.getPage(
          TransactionPageRequest(
            range: range.value,
            filter: filter.value,
            query: query.value,
            sort: sort.value,
            limit: pageSize,
          ),
        );
        final categoryRepository = _categoryRepository;
        final loadedCategories = categoryRepository == null
            ? <CategoryModel>[]
            : await categoryRepository.getAll(includeArchived: true);
        if (requestId != _requestId) return;
        _loadedCount = page.length;
        hasMore.value = page.length == pageSize;
        categories.assignAll(loadedCategories);
        state.value = page.isEmpty
            ? const ResourceState.empty()
            : ResourceState.success(page);
        return;
      }
      final transactions = await _repository.getAll(range: range.value);
      final categoryRepository = _categoryRepository;
      final loadedCategories = categoryRepository == null
          ? <CategoryModel>[]
          : await categoryRepository.getAll(includeArchived: true);
      if (requestId != _requestId) return;
      categories.assignAll(loadedCategories);
      state.value = transactions.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(transactions);
    } catch (_) {
      if (requestId != _requestId) return;
      state.value = const ResourceState.error('Gagal memuat transaksi.');
    }
  }

  Future<void> loadNextPage() async {
    final pageRepository = _pageRepository;
    if (pageRepository == null ||
        !hasMore.value ||
        isLoadingMore.value ||
        state.value.status != ResourceStatus.success) {
      return;
    }
    isLoadingMore.value = true;
    try {
      final page = await pageRepository.getPage(
        TransactionPageRequest(
          range: range.value,
          filter: filter.value,
          query: query.value,
          sort: sort.value,
          limit: pageSize,
          offset: _loadedCount,
        ),
      );
      final current = state.value.data ?? const <TransactionModel>[];
      final combined = [...current, ...page];
      _loadedCount = combined.length;
      hasMore.value = page.length == pageSize;
      state.value = ResourceState.success(combined);
    } catch (_) {
      // Halaman yang sudah tampil tetap dipertahankan saat halaman berikutnya gagal.
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _resetPagedLoad() {
    if (_pageRepository == null) return;
    load(silent: true);
  }

  Future<void> _afterMutation() async {
    if (Get.isRegistered<DataRefreshService>()) {
      Get.find<DataRefreshService>().bump();
    } else {
      await load(silent: true);
    }
  }

  Future<bool> save(TransactionModel transaction) async {
    final titleError = requiredText(
      transaction.title,
      fieldName: 'Nama transaksi',
    );
    final amountError = positiveAmount(transaction.amount);
    if (titleError != null ||
        amountError != null ||
        transaction.categoryId <= 0) {
      return false;
    }
    try {
      if (transaction.id == null) {
        await _repository.insert(transaction);
      } else {
        await _repository.update(transaction);
      }
      await _afterMutation();
      return true;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menyimpan transaksi.');
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      await _afterMutation();
      return true;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menghapus transaksi.');
      return false;
    }
  }

  /// Menggandakan transaksi ke hari ini.
  Future<bool> duplicate(TransactionModel transaction) async {
    try {
      final now = DateTime.now();
      await _repository.insert(
        TransactionModel(
          type: transaction.type,
          title: transaction.title,
          amount: transaction.amount,
          currency: transaction.currency,
          transactionDate: now,
          categoryId: transaction.categoryId,
          merchantOrSource: transaction.merchantOrSource,
          paymentMethod: transaction.paymentMethod,
          note: transaction.note,
          receiptPath: transaction.receiptPath,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _afterMutation();
      return true;
    } catch (_) {
      state.value = const ResourceState.error('Gagal menduplikasi transaksi.');
      return false;
    }
  }
}
