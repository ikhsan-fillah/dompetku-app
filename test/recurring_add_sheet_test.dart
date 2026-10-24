import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/recurring/controllers/recurring_controller.dart';
import 'package:dompetku_app/features/recurring/controllers/recurring_form_controller.dart';
import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:dompetku_app/features/recurring/pages/recurring_add_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Store implements RecurringStore {
  final List<RecurringRule> items = [];

  @override
  Future<List<RecurringRule>> getAll() async => List.of(items);

  @override
  Future<int> insert(RecurringRule rule) async {
    items.add(rule);
    return items.length;
  }

  @override
  Future<void> setActive(int id, bool active) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> markGenerated(int id, DateTime day) async {}

  @override
  Future<void> update(RecurringRule rule) async {
    final index = items.indexWhere((r) => r.id == rule.id);
    if (index >= 0) items[index] = rule;
  }
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async => [
    CategoryModel(
      id: 3,
      name: 'Bills',
      type: TransactionType.expense,
      iconKey: 'receipt_long',
      colorValue: 0xFF5B7B6A,
      isDefault: true,
      isFavorite: false,
      sortOrder: 0,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
  });

  testWidgets('sheet tambah menyimpan aturan dan menutup sheet', (
    tester,
  ) async {
    final store = _Store();
    Get.put(RecurringController(store));
    Get.put(RecurringFormController(store));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showRecurringAddSheet(context, categories: _Categories()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Simpan transaksi berulang'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Listrik');
    await tester.enterText(find.byKey(const Key('amount')), '438000');
    await tester.pump();
    await tester.tap(find.text('Bills'));
    await tester.pump();

    await tester.tap(find.text('Simpan transaksi berulang'));
    await tester.pumpAndSettle();

    expect(store.items.single.name, 'Listrik');
    expect(store.items.single.amount, 438000);
    expect(find.text('Simpan transaksi berulang'), findsNothing);
  });
}
