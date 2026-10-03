import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';

import '../data/transaction_local_data_source.dart';
import '../models/transaction_model.dart';
import 'transaction_repository.dart';
import '../services/transaction_list_service.dart';

class TransactionRepositoryImpl
    implements TransactionRepository, TransactionPageRepository {
  TransactionRepositoryImpl(this._dataSource);

  final TransactionLocalDataSource _dataSource;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) {
    return _dataSource.getAll(range: range);
  }

  @override
  Future<TransactionModel?> getById(int id) => _dataSource.getById(id);

  @override
  Future<int> insert(TransactionModel transaction) =>
      _dataSource.insert(transaction);

  @override
  Future<void> update(TransactionModel transaction) =>
      _dataSource.update(transaction);

  @override
  Future<void> delete(int id) => _dataSource.delete(id);

  @override
  Future<List<TransactionModel>> getByCategory(int categoryId) {
    return _dataSource.getByCategory(categoryId);
  }

  @override
  Future<int> getTotal({required TransactionType type, DateRange? range}) {
    return _dataSource.getTotal(type: type, range: range);
  }

  @override
  Future<List<TransactionModel>> getPage(TransactionPageRequest request) =>
      _dataSource.getPage(request);

  @override
  Future<TransactionSummary> getSummary({
    DateRange? range,
    TransactionTypeFilter filter = TransactionTypeFilter.all,
    String query = '',
  }) => _dataSource.getSummary(range: range, filter: filter, query: query);

  @override
  Future<CategoryTransactionSummary> getCategorySummary({
    required int categoryId,
    DateRange? range,
  }) => _dataSource.getCategorySummary(categoryId: categoryId, range: range);
}
