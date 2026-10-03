import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';

import '../models/transaction_model.dart';
import '../services/transaction_list_service.dart';

class TransactionPageRequest {
  const TransactionPageRequest({
    this.range,
    this.filter = TransactionTypeFilter.all,
    this.query = '',
    this.sort = TransactionSort.terbaru,
    this.limit = 25,
    this.offset = 0,
  });

  final DateRange? range;
  final TransactionTypeFilter filter;
  final String query;
  final TransactionSort sort;
  final int limit;
  final int offset;
}

class TransactionSummary {
  const TransactionSummary({required this.income, required this.expense});

  final int income;
  final int expense;
}

abstract interface class TransactionPageRepository {
  Future<List<TransactionModel>> getPage(TransactionPageRequest request);

  Future<TransactionSummary> getSummary({
    DateRange? range,
    TransactionTypeFilter filter = TransactionTypeFilter.all,
    String query = '',
  });
}

abstract interface class TransactionRepository {
  Future<List<TransactionModel>> getAll({DateRange? range});
  Future<TransactionModel?> getById(int id);
  Future<int> insert(TransactionModel transaction);
  Future<void> update(TransactionModel transaction);
  Future<void> delete(int id);
  Future<List<TransactionModel>> getByCategory(int categoryId);
  Future<int> getTotal({required TransactionType type, DateRange? range});
}
