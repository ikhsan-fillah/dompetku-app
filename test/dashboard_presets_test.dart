import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Transactions implements TransactionRepository {
  _Transactions(this.items);

  final List<TransactionModel> items;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Budgets implements BudgetRepository {
  _Budgets(this.items);

  final List<BudgetModel> items;

  @override
  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async =>
      items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DashboardController _controller({
  List<TransactionModel> transactions = const [],
  List<BudgetModel> budgets = const [],
}) {
  return DashboardController(
    _Transactions(transactions),
    const FinancialCalculationService(),
    _Categories(),
    budgets: _Budgets(budgets),
  );
}

void main() {
  tearDown(Get.reset);

  test('setPreset mengganti rentang dan chip aktif', () async {
    final controller = Get.put(_controller());
    await pumpEventQueue();

    await controller.setPreset(DateRangePreset.today);
    expect(controller.preset.value, DateRangePreset.today);
    expect(controller.range.value.dayCount, 1);

    await controller.setPreset(DateRangePreset.week);
    expect(controller.preset.value, DateRangePreset.week);
    expect(controller.range.value.dayCount, 7);
  });

  test('setRange menandai preset kustom', () async {
    final controller = Get.put(_controller());
    await pumpEventQueue();

    await controller.setRange(
      DateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 20)),
    );
    expect(controller.preset.value, DateRangePreset.custom);
    expect(controller.range.value.dayCount, 11);
  });

  test('anggaran keseluruhan yang aktif muncul di data dashboard', () async {
    final now = DateTime.now();
    final controller = Get.put(
      _controller(
        transactions: [
          TransactionModel(
            id: 1,
            type: TransactionType.expense,
            title: 'Makan',
            amount: 250000,
            transactionDate: now,
            categoryId: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        budgets: [
          BudgetModel(
            id: 1,
            name: 'Bulan ini',
            amountLimit: 1000000,
            startDate: DateTime(now.year, now.month, 1),
            endDate: DateTime(now.year, now.month + 1, 0),
            isArchived: false,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );
    await pumpEventQueue();

    expect(controller.state.value.status, ResourceStatus.success);
    final budget = controller.state.value.data!.budget;
    expect(budget, isNotNull);
    expect(budget!.percent, 25);
    expect(controller.state.value.data!.recent.length, 1);
  });
}
