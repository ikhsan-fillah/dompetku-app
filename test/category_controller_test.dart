import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/features/category/controllers/category_controller.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryModel _category(
  int? id,
  String name,
  TransactionType type, {
  bool favorite = false,
  bool archived = false,
  int sort = 0,
}) {
  return CategoryModel(
    id: id,
    name: name,
    type: type,
    iconKey: 'more_horiz',
    colorValue: 0xFF90A4AE,
    isDefault: false,
    isFavorite: favorite,
    sortOrder: sort,
    isArchived: archived,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

CategoryModel _copy(
  CategoryModel c, {
  int? id,
  bool? isFavorite,
  bool? isArchived,
}) {
  return CategoryModel(
    id: id ?? c.id,
    name: c.name,
    type: c.type,
    iconKey: c.iconKey,
    colorValue: c.colorValue,
    isDefault: c.isDefault,
    isFavorite: isFavorite ?? c.isFavorite,
    sortOrder: c.sortOrder,
    isArchived: isArchived ?? c.isArchived,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  );
}

class _FakeCategoryRepository implements CategoryRepository {
  final items = <CategoryModel>[];
  bool fail = false;
  int insertCalls = 0;
  List<int>? lastReorder;
  int _nextId = 100;

  void _check() {
    if (fail) throw StateError('repository failed');
  }

  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async {
    _check();
    return items.where((c) => includeArchived || !c.isArchived).toList();
  }

  @override
  Future<CategoryModel?> getById(int id) async {
    _check();
    for (final c in items) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<int> insert(CategoryModel category) async {
    _check();
    insertCalls++;
    final id = _nextId++;
    items.add(_copy(category, id: id));
    return id;
  }

  @override
  Future<void> update(CategoryModel category) async {
    _check();
    final index = items.indexWhere((c) => c.id == category.id);
    if (index >= 0) items[index] = category;
  }

  @override
  Future<void> archive(int id) async {
    _check();
    final index = items.indexWhere((c) => c.id == id);
    if (index >= 0) items[index] = _copy(items[index], isArchived: true);
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    _check();
    lastReorder = orderedIds;
  }
}

void main() {
  late _FakeCategoryRepository repository;
  late CategoryController controller;

  setUp(() {
    repository = _FakeCategoryRepository();
    controller = CategoryController(repository);
  });

  test('load menampilkan data saat kategori tersedia', () async {
    repository.items.add(_category(1, 'Makan', TransactionType.expense));

    await controller.load();

    expect(controller.state.value.status, ResourceStatus.success);
    expect(controller.state.value.data, hasLength(1));
  });

  test('load menampilkan state kosong bila tidak ada kategori', () async {
    await controller.load();

    expect(controller.state.value.status, ResourceStatus.empty);
  });

  test('load menampilkan error saat repository gagal', () async {
    repository.fail = true;

    await controller.load();

    expect(controller.state.value.status, ResourceStatus.error);
    expect(controller.state.value.message, 'Gagal memuat kategori.');
  });

  test('visibleCategories mengikuti tipe yang dipilih', () async {
    repository.items.addAll([
      _category(1, 'Makan', TransactionType.expense),
      _category(2, 'Gaji', TransactionType.income),
    ]);
    await controller.load();

    expect(controller.visibleCategories.map((c) => c.name), ['Makan']);

    controller.setType(TransactionType.income);

    expect(controller.visibleCategories.map((c) => c.name), ['Gaji']);
  });

  test('save menolak nama kosong tanpa menyentuh repository', () async {
    final saved = await controller.save(
      _category(null, '', TransactionType.expense),
    );

    expect(saved, isFalse);
    expect(controller.state.value.status, ResourceStatus.error);
    expect(repository.insertCalls, 0);
  });

  test('save menambah kategori baru', () async {
    final saved = await controller.save(
      _category(null, 'Kopi', TransactionType.expense),
    );

    expect(saved, isTrue);
    expect(repository.insertCalls, 1);
    expect(controller.state.value.data!.map((c) => c.name), ['Kopi']);
  });

  test('save memperbarui kategori yang sudah ada', () async {
    repository.items.add(_category(1, 'Makan', TransactionType.expense));

    final saved = await controller.save(
      _category(1, 'Makan siang', TransactionType.expense),
    );

    expect(saved, isTrue);
    expect(repository.insertCalls, 0);
    expect(repository.items.single.name, 'Makan siang');
  });

  test('save menangani kegagalan repository', () async {
    repository.fail = true;

    final saved = await controller.save(
      _category(null, 'Kopi', TransactionType.expense),
    );

    expect(saved, isFalse);
    expect(controller.state.value.message, 'Gagal menyimpan kategori.');
  });

  test('archive menyembunyikan kategori dari daftar aktif', () async {
    repository.items.addAll([
      _category(1, 'Makan', TransactionType.expense),
      _category(2, 'Belanja', TransactionType.expense),
    ]);
    await controller.load();

    final archived = await controller.archive(1);

    expect(archived, isTrue);
    expect(controller.state.value.data!.map((c) => c.name), ['Belanja']);
    expect(repository.items.length, 2);
  });

  test('archive menangani kegagalan repository', () async {
    repository.fail = true;

    final archived = await controller.archive(1);

    expect(archived, isFalse);
    expect(controller.state.value.message, 'Gagal mengarsipkan kategori.');
  });

  test('toggleFavorite membalik status favorit', () async {
    final category = _category(1, 'Makan', TransactionType.expense);
    repository.items.add(category);
    await controller.load();

    final toggled = await controller.toggleFavorite(category);

    expect(toggled, isTrue);
    expect(repository.items.single.isFavorite, isTrue);
  });

  test('toggleFavorite menolak kategori tanpa id', () async {
    final toggled = await controller.toggleFavorite(
      _category(null, 'Baru', TransactionType.expense),
    );

    expect(toggled, isFalse);
  });

  test('moveWithinType mengubah urutan hanya pada tipe terpilih', () async {
    repository.items.addAll([
      _category(1, 'A', TransactionType.expense),
      _category(2, 'X', TransactionType.income),
      _category(3, 'B', TransactionType.expense),
      _category(4, 'C', TransactionType.expense),
    ]);
    await controller.load();

    final moved = await controller.moveWithinType(0, 3);

    expect(moved, isTrue);
    expect(repository.lastReorder, [3, 2, 4, 1]);
  });

  test('moveWithinType menolak indeks di luar daftar', () async {
    repository.items.add(_category(1, 'A', TransactionType.expense));
    await controller.load();

    final moved = await controller.moveWithinType(5, 0);

    expect(moved, isFalse);
    expect(repository.lastReorder, isNull);
  });
}
