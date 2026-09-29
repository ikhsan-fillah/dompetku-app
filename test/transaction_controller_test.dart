import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/transaction/controllers/transaction_controller.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/transaction/services/transaction_list_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Transactions implements TransactionRepository {
  _Transactions(this.items);

  final List<TransactionModel> items;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async =>
      List.of(items);

  @override
  Future<void> delete(int id) async {
    items.removeWhere((item) => item.id == id);
  }

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

TransactionModel _tx(int id, TransactionType type, int amount) {
  final at = DateTime(2026, 9, 20 + id);
  return TransactionModel(
    id: id,
    type: type,
    title: 'T$id',
    amount: amount,
    transactionDate: at,
    categoryId: 1,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  tearDown(Get.reset);

  test('memuat lalu memfilter jenis dan mencari', () async {
    final controller = Get.put(
      TransactionController(
        _Transactions([
          _tx(1, TransactionType.expense, 10),
          _tx(2, TransactionType.income, 500),
          _tx(3, TransactionType.expense, 30),
        ]),
        categories: _Categories(),
      ),
    );
    await pumpEventQueue();
    expect(controller.state.value.status, ResourceStatus.success);
    expect(controller.list.groups.expand((g) => g.items).length, 3);

    controller.setFilter(TransactionTypeFilter.expense);
    expect(controller.list.groups.expand((g) => g.items).length, 2);
    expect(controller.list.expense, 40);

    controller.setQuery('T3');
    expect(controller.list.groups.expand((g) => g.items).single.id, 3);
  });

  test('hapus memuat ulang daftar saat tidak ada layanan refresh', () async {
    final repository = _Transactions([
      _tx(1, TransactionType.expense, 10),
      _tx(2, TransactionType.expense, 20),
    ]);
    final controller = Get.put(
      TransactionController(repository, categories: _Categories()),
    );
    await pumpEventQueue();

    expect(await controller.delete(1), isTrue);
    await pumpEventQueue();
    expect(controller.state.value.data!.length, 1);
    expect(controller.findById(1), isNull);
    expect(controller.findById(2), isNotNull);
  });
}
