import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/budget/controllers/budget_controller.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/budget/views/budget_archive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime(2026, 9, 29, 12);

class _Budgets implements BudgetRepository {
  _Budgets(this.items);

  final List<BudgetModel> items;

  @override
  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async =>
      includeArchived
      ? List.of(items)
      : items.where((budget) => !budget.isArchived).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BudgetModel _budget(int id, {required bool archived, String name = 'Makan'}) =>
    BudgetModel(
      id: id,
      name: name,
      amountLimit: 1000000,
      categoryId: 1,
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      isArchived: archived,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  tearDown(Get.reset);

  Future<BudgetController> open(
    WidgetTester tester,
    List<BudgetModel> items,
  ) async {
    final controller = Get.put(BudgetController(_Budgets(items)));
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const BudgetArchivePage()),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'belum ada yang diarsipkan menampilkan keterangan, bukan loading',
    (tester) async {
      final controller = await open(tester, [_budget(1, archived: false)]);

      expect(controller.archived.value.status, ResourceStatus.empty);
      expect(find.text('Tidak ada anggaran terarsip'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('hanya anggaran terarsip yang ditampilkan', (tester) async {
    await open(tester, [
      _budget(1, archived: false, name: 'Aktif'),
      _budget(2, archived: true, name: 'Lama'),
    ]);

    expect(find.textContaining('Lama'), findsWidgets);
    expect(find.textContaining('Aktif'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
