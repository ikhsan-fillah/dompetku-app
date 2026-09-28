import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';

import '../models/transaction_model.dart';

abstract interface class TransactionRepository {
  Future<List<TransactionModel>> getAll({DateRange? range});
  Future<TransactionModel?> getById(int id);
  Future<int> insert(TransactionModel transaction);
  Future<void> update(TransactionModel transaction);
  Future<void> delete(int id);
  Future<List<TransactionModel>> getByCategory(int categoryId);
  Future<int> getTotal({required TransactionType type, DateRange? range});
}
