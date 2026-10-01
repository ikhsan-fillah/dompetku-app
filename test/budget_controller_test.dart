import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/features/budget/controllers/budget_controller.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime(2026, 9, 29, 12);

class _Budgets implements BudgetRepository {
  _Budgets(this.items);
  final List<BudgetModel> items;
  final archived = <int>[];
  final restored = <int>[];
  @override
  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async => List.of(items);
  @override
  Future<void> archive(int id) async { archived.add(id); items.removeWhere((item) => item.id == id); }
  @override
  Future<void> restore(int id) async { restored.add(id); }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transactions implements TransactionRepository {
  _Transactions(this.items);
  final List<TransactionModel> items;
  @override
  Future<List<TransactionModel>> getAll({dynamic range}) async => items;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BudgetModel _budget({int id = 1, int? categoryId}) => BudgetModel(
  id: id, name: categoryId == null ? 'Bulan ini' : 'Makan', amountLimit: 1000000, categoryId: categoryId,
  startDate: DateTime(2026, 9, 1), endDate: DateTime(2026, 9, 30), isArchived: false, createdAt: _now, updatedAt: _now,
);
TransactionModel _tx(int amount, {int categoryId = 1}) => TransactionModel(
  type: TransactionType.expense, title: 'T', amount: amount, transactionDate: DateTime(2026, 9, 10), categoryId: categoryId, createdAt: _now, updatedAt: _now,
);

void main() {
  tearDown(Get.reset);
  test('menghasilkan progres keseluruhan dan per kategori', () async {
    final controller = Get.put(BudgetController(_Budgets([_budget(), _budget(id: 2, categoryId: 2)]), transactions: _Transactions([_tx(400000, categoryId: 1), _tx(600000, categoryId: 2)])));
    await pumpEventQueue();
    expect(controller.state.value.status, ResourceStatus.success);
    final budgets = controller.state.value.data!;
    expect(budgets[0].used, 1000000);
    expect(budgets[0].percent, 100);
    expect(budgets[1].used, 600000);
    expect(budgets[1].percent, 60);
  });
  test('arsip memanggil repository dan memuat ulang', () async {
    final repository = _Budgets([_budget()]);
    final controller = Get.put(BudgetController(repository));
    await pumpEventQueue();
    expect(await controller.archive(1), isTrue);
    await pumpEventQueue();
    expect(repository.archived, [1]);
    expect(controller.state.value.status, ResourceStatus.empty);
  });
  test('pulihkan memanggil repository dan memuat ulang daftar terarsip', () async {
    final repository = _Budgets([]);
    final controller = Get.put(BudgetController(repository));
    await pumpEventQueue();
    expect(await controller.restore(7), isTrue);
    await pumpEventQueue();
    expect(repository.restored, [7]);
    expect(controller.archived.value.status, ResourceStatus.empty);
  });
  test('pulihkan gagal bila repository melempar', () async {
    final repository = _BrokenBudgets();
    final controller = Get.put(BudgetController(repository));
    await pumpEventQueue();
    expect(await controller.restore(1), isFalse);
    expect(controller.archived.value.status, ResourceStatus.error);
  });
}

class _BrokenBudgets implements BudgetRepository {
  @override
  Future<void> restore(int id) async => throw StateError('db error');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
