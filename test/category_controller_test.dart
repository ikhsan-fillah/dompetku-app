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
  Future<void> delete(int id) async {
    _check();
    items.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    _check();
    lastReorder = orderedIds;
    items.sort(
      (a, b) => orderedIds.indexOf(a.id!).compareTo(orderedIds.indexOf(b.id!)),
    );
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

  test('delete menghapus kategori dari daftar', () async {
    repository.items.addAll([
      _category(1, 'Makan', TransactionType.expense),
      _category(2, 'Belanja', TransactionType.expense),
    ]);
    await controller.load();

    final deleted = await controller.delete(1);

    expect(deleted, isTrue);
    expect(controller.state.value.data!.map((c) => c.name), ['Belanja']);
    expect(repository.items.length, 1);
  });

  test('delete gagal memberi pesan tanpa mengganti daftar', () async {
    repository.items.add(_category(1, 'Makan', TransactionType.expense));
    await controller.load();
    repository.fail = true;

    final deleted = await controller.delete(1);

    expect(deleted, isFalse);
    expect(controller.lastError.value, 'Gagal menghapus kategori.');
    expect(controller.state.value.data, isNotEmpty);
  });

  group('favorit', () {
    List<String> names() =>
        controller.visibleCategories.map((c) => c.name).toList();

    CategoryModel byName(String name) =>
        controller.visibleCategories.firstWhere((c) => c.name == name);

    test('favorit baru naik ke atas, di ujung blok favorit', () async {
      repository.items.addAll([
        _category(1, 'A', TransactionType.expense),
        _category(2, 'B', TransactionType.expense),
        _category(3, 'C', TransactionType.expense),
        _category(4, 'D', TransactionType.expense),
      ]);
      await controller.load();

      await controller.toggleFavorite(byName('C'));
      expect(names(), ['C', 'A', 'B', 'D']);

      await controller.toggleFavorite(byName('D'));
      expect(names(), ['C', 'D', 'A', 'B']);
      expect(byName('C').isFavorite && byName('D').isFavorite, isTrue);
    });

    test('melepas favorit memindahkannya ke awal daftar biasa', () async {
      repository.items.addAll([
        _category(1, 'A', TransactionType.expense),
        _category(2, 'B', TransactionType.expense),
        _category(3, 'C', TransactionType.expense),
      ]);
      await controller.load();
      await controller.toggleFavorite(byName('B'));
      await controller.toggleFavorite(byName('C'));
      expect(names(), ['B', 'C', 'A']);

      await controller.toggleFavorite(byName('B'));

      expect(names(), ['C', 'B', 'A']);
      expect(byName('B').isFavorite, isFalse);
    });

    test('maksimal 4 favorit per jenis', () async {
      repository.items.addAll([
        for (var i = 1; i <= 5; i++)
          _category(i, 'K$i', TransactionType.expense),
        _category(6, 'Gaji', TransactionType.income),
      ]);
      await controller.load();
      for (var i = 1; i <= 4; i++) {
        expect(await controller.toggleFavorite(byName('K$i')), isTrue);
      }

      final fifth = await controller.toggleFavorite(byName('K5'));

      expect(fifth, isFalse);
      expect(controller.lastError.value, 'Maksimal 4 kategori favorit.');
      expect(byName('K5').isFavorite, isFalse);
      expect(controller.favoriteCount(TransactionType.expense), 4);
      expect(controller.state.value.data, isNotEmpty);

      // Jenis lain punya jatahnya sendiri.
      controller.setType(TransactionType.income);
      expect(await controller.toggleFavorite(byName('Gaji')), isTrue);
    });

    test('geser kategori biasa ke atas tetap di bawah favorit', () async {
      repository.items.addAll([
        _category(1, 'A', TransactionType.expense),
        _category(2, 'B', TransactionType.expense),
        _category(3, 'C', TransactionType.expense),
      ]);
      await controller.load();
      await controller.toggleFavorite(byName('A'));

      await controller.moveWithinType(2, 0);

      expect(names(), ['A', 'C', 'B']);
    });

    test('favoritesFirst menjaga urutan dalam tiap blok', () {
      final a = _category(1, 'A', TransactionType.expense);
      final b = _category(2, 'B', TransactionType.expense);
      final c = _category(3, 'C', TransactionType.expense);

      final ordered = CategoryController.favoritesFirst(
        [a, b, c],
        changedId: 3,
        nowFavorite: true,
      );

      expect(ordered.map((x) => x.name), ['C', 'A', 'B']);
    });
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

  test('moveWithinType bisa geser ke atas ke posisi mana pun', () async {
    repository.items.addAll([
      _category(1, 'A', TransactionType.expense),
      _category(2, 'B', TransactionType.expense),
      _category(3, 'C', TransactionType.expense),
    ]);
    await controller.load();

    final moved = await controller.moveWithinType(2, 0);

    expect(moved, isTrue);
    expect(repository.lastReorder, [3, 1, 2]);
  });

  test('moveWithinType menolak indeks di luar daftar', () async {
    repository.items.add(_category(1, 'A', TransactionType.expense));
    await controller.load();

    final moved = await controller.moveWithinType(5, 0);

    expect(moved, isFalse);
    expect(repository.lastReorder, isNull);
  });
}
