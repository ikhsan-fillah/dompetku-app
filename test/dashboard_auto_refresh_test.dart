import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/data_refresh_service.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeTransactions implements TransactionRepository {
  int getAllCalls = 0;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async {
    getAllCalls++;
    final now = DateTime.now();
    return [
      TransactionModel(
        type: TransactionType.expense,
        title: 'Makan',
        amount: 1000,
        transactionDate: now,
        categoryId: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<TransactionModel?> getById(int id) async => null;

  @override
  Future<int> insert(TransactionModel transaction) async => 1;

  @override
  Future<void> update(TransactionModel transaction) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<TransactionModel>> getByCategory(int categoryId) async => [];

  @override
  Future<int> getTotal({
    required TransactionType type,
    DateRange? range,
  }) async => 0;
}

class _FakeCategories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async =>
      [];

  @override
  Future<CategoryModel?> getById(int id) async => null;

  @override
  Future<int> insert(CategoryModel category) async => 1;

  @override
  Future<void> update(CategoryModel category) async {}

  @override
  Future<void> archive(int id) async {}

  @override
  Future<void> reorder(List<int> orderedIds) async {}
}

void main() {
  tearDown(Get.reset);

  test('dashboard memuat ulang otomatis saat sinyal data berubah', () async {
    final refresh = Get.put(DataRefreshService());
    final repository = _FakeTransactions();
    final controller = DashboardController(
      repository,
      const FinancialCalculationService(),
      _FakeCategories(),
    );
    Get.put(controller);
    await pumpEventQueue();
    expect(repository.getAllCalls, 1);
    expect(controller.state.value.status, ResourceStatus.success);

    refresh.bump();
    await pumpEventQueue();
    expect(repository.getAllCalls, 2);
    expect(controller.state.value.status, ResourceStatus.success);
  });
}
