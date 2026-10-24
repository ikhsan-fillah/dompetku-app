import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/budget/controllers/budget_controller.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/models/budget_view_model.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/budget/views/budget_page.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime(2026, 9, 29, 12);

class _Budgets implements BudgetRepository {
  _Budgets(this.items);

  final List<BudgetModel> items;
  final deleted = <int>[];

  @override
  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async =>
      items.where((budget) => !budget.isArchived).toList();

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    items.removeWhere((budget) => budget.id == id);
  }

  @override
  Future<int> insert(BudgetModel budget) async {
    items.add(budget);
    return budget.id ?? items.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async => [
    CategoryModel(
      id: 1,
      name: 'Food & Drink',
      type: TransactionType.expense,
      iconKey: 'utensils',
      colorValue: 0xFFD39A2B,
      isDefault: false,
      isFavorite: false,
      sortOrder: 0,
      isArchived: false,
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BudgetModel _budget(int id, String name, {int categoryId = 1}) => BudgetModel(
  id: id,
  name: name,
  amountLimit: 1000000,
  categoryId: categoryId,
  startDate: DateTime(2026, 9, 1),
  endDate: DateTime(2026, 9, 30),
  isArchived: false,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  tearDown(Get.reset);

  group('labelsFor', () {
    BudgetViewModel item(String name) =>
        BudgetViewModel(budget: _budget(1, name), used: 0);

    test('nama bawaan sama dengan kategori jadi satu judul', () {
      final labels = item('Anggaran Makanan').labelsFor('Makanan');

      expect(labels.title, 'Makanan');
      expect(labels.category, isNull);
    });

    test('nama buatan sendiri tetap judul, kategori jadi keterangan', () {
      final labels = item('makan').labelsFor('Food & Drink');

      expect(labels.title, 'makan');
      expect(labels.category, 'Food & Drink');
    });

    test('nama sama persis dengan kategori tidak ditulis dua kali', () {
      final labels = item('makanan').labelsFor('Makanan');

      expect(labels.title, 'Makanan');
      expect(labels.category, isNull);
    });

    test('tanpa nama kategori judul memakai nama anggaran', () {
      final labels = item('makan').labelsFor(null);

      expect(labels.title, 'makan');
      expect(labels.category, isNull);
    });
  });

  group('halaman anggaran', () {
    Future<BudgetController> open(
      WidgetTester tester,
      List<BudgetModel> items,
    ) async {
      final controller = Get.put(
        BudgetController(_Budgets(items), categories: _Categories()),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: BudgetPage()),
        ),
      );
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('nama anggaran dan kategori tampil satu kali masing-masing', (
      tester,
    ) async {
      await open(tester, [_budget(1, 'makan')]);

      expect(find.text('makan'), findsOneWidget);
      expect(find.textContaining('Food & Drink'), findsOneWidget);
    });

    testWidgets('semua anggaran tampil walau lebih dari 3', (tester) async {
      await open(tester, [
        for (var i = 1; i <= 5; i++) _budget(i, 'Anggaran $i'),
      ]);

      expect(find.textContaining('Food & Drink'), findsNWidgets(5));
      expect(find.textContaining('Lihat semua'), findsNothing);
    });

    testWidgets('Hapus langsung menghapus dengan toast Urungkan', (
      tester,
    ) async {
      final repository = _Budgets([_budget(1, 'makan'), _budget(2, 'jajan')]);
      Get.put(BudgetController(repository, categories: _Categories()));
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: BudgetPage()),
        ),
      );
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      // Aksi hanya lewat geser kartu ke kiri.
      await tester.drag(find.text('makan'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      // Arsip ada di lembar Edit, bukan di aksi geser.
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Arsipkan'), findsNothing);
      await tester.tap(find.text('Hapus'));
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Hapus anggaran?'), findsNothing);
      expect(repository.deleted, [1]);
      expect(find.text('Anggaran dihapus'), findsOneWidget);
      expect(find.text('jajan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('Urungkan mengembalikan anggaran yang dihapus', (tester) async {
      final repository = _Budgets([_budget(1, 'makan')]);
      Get.put(BudgetController(repository, categories: _Categories()));
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: BudgetPage()),
        ),
      );
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      // Aksi hanya lewat geser kartu ke kiri.
      await tester.drag(find.text('makan'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Urungkan'));
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(repository.items.map((b) => b.name), ['makan']);
      expect(find.text('makan'), findsOneWidget);
    });
  });
}
