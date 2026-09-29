import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/budget/controllers/budget_form_controller.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime(2026, 9, 29, 12);

class _FakeBudgets implements BudgetRepository {
  final inserted = <BudgetModel>[];
  final updated = <BudgetModel>[];

  @override
  Future<List<BudgetModel>> getAll({bool includeArchived = false}) async => const [];

  @override
  Future<BudgetModel?> getById(int id) async => null;

  @override
  Future<int> insert(BudgetModel budget) async {
    inserted.add(budget);
    return 1;
  }

  @override
  Future<void> update(BudgetModel budget) async => updated.add(budget);

  @override
  Future<void> archive(int id) async {}
}

class _FakeCategories implements CategoryRepository {
  _FakeCategories(this.items);
  final List<CategoryModel> items;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<List<CategoryModel>>.value(items);
}

TransactionType get _otherType =>
    TransactionType.values.firstWhere((type) => type.name != 'expense');

CategoryModel _category({
  int? id,
  TransactionType type = TransactionType.expense,
  bool archived = false,
}) =>
    CategoryModel(
      id: id,
      name: 'Kategori ${id ?? 'x'}',
      type: type,
      iconKey: 'icon',
      colorValue: 0xFF000000,
      isDefault: false,
      isFavorite: false,
      sortOrder: 0,
      isArchived: archived,
      createdAt: _now,
      updatedAt: _now,
    );

BudgetModel _existing() => BudgetModel(
      id: 7,
      name: 'Makan',
      amountLimit: 500000,
      categoryId: 1,
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      isArchived: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeBudgets budgets;
  late BudgetFormController controller;

  setUp(() {
    budgets = _FakeBudgets();
    controller = BudgetFormController(budgets, _FakeCategories(const []));
  });

  tearDown(Get.reset);

  test('menolak nama kosong', () async {
    await controller.startNew(now: DateTime(2026, 9, 29));
    controller.amountDigits.value = '100000';

    expect(await controller.save(), isFalse);
    expect(controller.error.value, 'Nama anggaran wajib diisi.');
    expect(budgets.inserted, isEmpty);
  });

  test('menolak batas nol atau kosong', () async {
    await controller.startNew(now: DateTime(2026, 9, 29));
    controller.name.value = 'Bulanan';

    expect(await controller.save(), isFalse);
    expect(controller.error.value, 'Batas anggaran harus lebih dari nol.');

    controller.amountDigits.value = '0';
    expect(await controller.save(), isFalse);
    expect(budgets.inserted, isEmpty);
  });

  test('menolak tanggal mulai setelah tanggal selesai', () async {
    await controller.startNew(now: DateTime(2026, 9, 29));
    controller.name.value = 'Bulanan';
    controller.amountDigits.value = '100000';
    controller.setDates(start: DateTime(2026, 9, 20), end: DateTime(2026, 9, 10));

    expect(await controller.save(), isFalse);
    expect(
      controller.error.value,
      'Tanggal mulai tidak boleh setelah tanggal selesai.',
    );
    expect(budgets.inserted, isEmpty);
  });

  test('menyimpan anggaran baru untuk bulan berjalan', () async {
    await controller.startNew(now: DateTime(2026, 9, 29));
    controller.name.value = '  Bulanan  ';
    controller.amountDigits.value = '2500000';

    expect(await controller.save(), isTrue);

    final saved = budgets.inserted.single;
    expect(saved.name, 'Bulanan');
    expect(saved.amountLimit, 2500000);
    expect(saved.categoryId, isNull);
    expect(saved.startDate, DateTime(2026, 9, 1));
    expect(saved.endDate, DateTime(2026, 9, 30));
    expect(saved.isArchived, isFalse);
  });

  test('edit memanggil update dan mempertahankan data lama', () async {
    final existing = _existing();
    await controller.startEdit(existing);
    controller.name.value = 'Makan siang';
    controller.amountDigits.value = '750000';

    expect(await controller.save(), isTrue);
    expect(budgets.inserted, isEmpty);

    final saved = budgets.updated.single;
    expect(saved.id, 7);
    expect(saved.name, 'Makan siang');
    expect(saved.amountLimit, 750000);
    expect(saved.categoryId, 1);
    expect(saved.createdAt, existing.createdAt);
    expect(saved.isArchived, isFalse);
  });

  test('hanya kategori pengeluaran aktif yang tersedia', () async {
    final filtered = BudgetFormController(
      budgets,
      _FakeCategories([
        _category(id: 1),
        _category(id: 2, archived: true),
        _category(id: 3, type: _otherType),
        _category(),
      ]),
    );

    await filtered.startNew(now: DateTime(2026, 9, 29));

    expect(filtered.availableCategories.map((item) => item.id), [1]);
  });
}
