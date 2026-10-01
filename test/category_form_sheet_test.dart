import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/category/controllers/category_controller.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/category/widgets/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime(2026, 9, 29, 12);

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository([List<CategoryModel>? initial])
    : items = [...?initial];

  final List<CategoryModel> items;
  final inserted = <CategoryModel>[];
  final updated = <CategoryModel>[];
  int _nextId = 10;

  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async {
    return items.where((item) => includeArchived || !item.isArchived).toList();
  }

  @override
  Future<CategoryModel?> getById(int id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<int> insert(CategoryModel category) async {
    inserted.add(category);
    items.add(_copy(category, id: _nextId++));
    return items.last.id!;
  }

  @override
  Future<void> update(CategoryModel category) async {
    updated.add(category);
    final index = items.indexWhere((item) => item.id == category.id);
    if (index >= 0) items[index] = category;
  }

  @override
  Future<void> archive(int id) async {}

  @override
  Future<void> reorder(List<int> orderedIds) async {}
}

CategoryModel _category(
  int id,
  String name,
  TransactionType type,
  int sortOrder,
) {
  return CategoryModel(
    id: id,
    name: name,
    type: type,
    iconKey: 'restaurant',
    colorValue: 0xFF0F766E,
    isDefault: false,
    isFavorite: false,
    sortOrder: sortOrder,
    isArchived: false,
    createdAt: _now,
    updatedAt: _now,
  );
}

CategoryModel _copy(CategoryModel category, {int? id}) {
  return CategoryModel(
    id: id ?? category.id,
    name: category.name,
    type: category.type,
    iconKey: category.iconKey,
    colorValue: category.colorValue,
    isDefault: category.isDefault,
    isFavorite: category.isFavorite,
    sortOrder: category.sortOrder,
    isArchived: category.isArchived,
    createdAt: category.createdAt,
    updatedAt: category.updatedAt,
  );
}

Future<void> _pumpForm(
  WidgetTester tester,
  _FakeCategoryRepository repository, {
  CategoryModel? category,
}) async {
  final controller = CategoryController(repository);
  Get.put(controller);
  await controller.load();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: CategoryFormSheet(category: category)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('kategori baru mendapat urutan terakhir untuk tipenya', (
    tester,
  ) async {
    final repository = _FakeCategoryRepository([
      _category(1, 'Makan', TransactionType.expense, 0),
      _category(2, 'Transportasi', TransactionType.expense, 3),
      _category(3, 'Gaji', TransactionType.income, 8),
    ]);
    await _pumpForm(tester, repository);

    await tester.enterText(find.byType(TextField), 'Kopi');
    await tester.ensureVisible(find.text('Simpan kategori'));
    await tester.tap(find.text('Simpan kategori'));
    await tester.pumpAndSettle();

    expect(repository.inserted.single.sortOrder, 4);
    expect(repository.inserted.single.type, TransactionType.expense);
  });

  testWidgets('tipe kategori terkunci saat edit', (tester) async {
    final existing = _category(1, 'Gaji', TransactionType.income, 2);
    final repository = _FakeCategoryRepository([existing]);
    await _pumpForm(tester, repository, category: existing);

    await tester.tap(find.text('Pengeluaran'));
    await tester.pump();
    await tester.ensureVisible(find.text('Perbarui kategori'));
    await tester.tap(find.text('Perbarui kategori'));
    await tester.pumpAndSettle();

    expect(repository.updated.single.type, TransactionType.income);
  });

  testWidgets('nama kategori wajib diisi', (tester) async {
    final repository = _FakeCategoryRepository();
    await _pumpForm(tester, repository);

    await tester.ensureVisible(find.text('Simpan kategori'));
    await tester.tap(find.text('Simpan kategori'));
    await tester.pump();

    expect(find.text('Nama kategori wajib diisi.'), findsOneWidget);
    expect(repository.inserted, isEmpty);
  });
}
