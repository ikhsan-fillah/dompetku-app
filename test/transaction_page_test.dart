import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/core/widgets/app_chip.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/transaction/controllers/transaction_controller.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/pages/transaction_list_page.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/transaction/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime.now();

class _Transactions implements TransactionRepository {
  _Transactions(this.items);

  final List<TransactionModel> items;
  final deleted = <int>[];

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async =>
      List.of(items);

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    items.removeWhere((item) => item.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async => [
        _cat(1, 'Makanan', TransactionType.expense),
        _cat(2, 'Transportasi', TransactionType.expense),
        _cat(3, 'Gaji', TransactionType.income),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CategoryModel _cat(int id, String name, TransactionType type) {
  return CategoryModel(
    id: id,
    name: name,
    type: type,
    iconKey: 'restaurant',
    colorValue: 0xFFE57373,
    isDefault: false,
    isFavorite: false,
    sortOrder: id,
    isArchived: false,
    createdAt: _now,
    updatedAt: _now,
  );
}

TransactionModel _tx(
  int id,
  TransactionType type,
  String title,
  int amount,
  int categoryId,
  DateTime date,
) {
  return TransactionModel(
    id: id,
    type: type,
    title: title,
    amount: amount,
    transactionDate: date,
    categoryId: categoryId,
    createdAt: date,
    updatedAt: date,
  );
}

List<TransactionModel> _sample() {
  final noon = DateTime(_now.year, _now.month, _now.day, 12);
  return [
    _tx(1, TransactionType.expense, 'Kopi', 25000, 1, noon),
    _tx(2, TransactionType.expense, 'Bensin', 50000, 2, noon),
    _tx(3, TransactionType.income, 'Gaji', 5000000, 3,
        noon.subtract(const Duration(days: 1))),
  ];
}

Future<_Transactions> _open(
  WidgetTester tester, {
  List<TransactionModel>? items,
}) async {
  await tester.binding.setSurfaceSize(const Size(500, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repository = _Transactions(items ?? _sample());
  Get.put(TransactionController(repository, categories: _Categories()));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: TransactionListPage()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Finder _incomeTile() => find.ancestor(
      of: find.text('+ Rp 5.000.000'),
      matching: find.byType(TransactionTile),
    );

void main() {
  tearDown(Get.reset);

  testWidgets('menampilkan ringkasan dan label hari', (tester) async {
    await _open(tester);
    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Bensin'), findsOneWidget);
    expect(_incomeTile(), findsOneWidget);
    expect(
      find.descendant(of: _incomeTile(), matching: find.text('Gaji')),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('Hari ini'), findsOneWidget);
    expect(find.textContaining('Kemarin'), findsOneWidget);
    expect(find.text('Rp 5.000.000'), findsOneWidget);
    expect(find.text('Rp 75.000'), findsOneWidget);
  });

  testWidgets('filter pengeluaran menyembunyikan pemasukan', (tester) async {
    await _open(tester);
    await tester.tap(find.widgetWithText(AppChip, 'Pengeluaran'));
    await tester.pumpAndSettle();
    expect(_incomeTile(), findsNothing);
    expect(find.text('Kopi'), findsOneWidget);
  });

  testWidgets('pencarian menyaring daftar', (tester) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'bensin');
    await tester.pumpAndSettle();
    expect(find.text('Bensin'), findsOneWidget);
    expect(find.text('Kopi'), findsNothing);
  });

  testWidgets('pencarian tanpa hasil menampilkan pesan', (tester) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'tidak ada');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada hasil'), findsOneWidget);
  });

  testWidgets('mengetuk baris menampilkan aksi dan hapus butuh konfirmasi',
      (tester) async {
    final repository = await _open(tester);

    await tester.tap(find.text('Kopi'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Duplikat'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus transaksi?'), findsOneWidget);
    expect(repository.deleted, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Hapus'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.deleted, [1]);
    expect(find.text('Kopi'), findsNothing);
    expect(find.text('Transaksi dihapus.'), findsOneWidget);
  });

  testWidgets('membatalkan hapus tidak menghapus apa pun', (tester) async {
    final repository = await _open(tester);

    await tester.tap(find.text('Kopi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repository.deleted, isEmpty);
    expect(find.text('Kopi'), findsOneWidget);
  });

  testWidgets('tanpa transaksi menampilkan ajakan menambah', (tester) async {
    await _open(tester, items: []);
    expect(find.text('Belum ada transaksi'), findsOneWidget);
    expect(find.text('Tambah transaksi'), findsOneWidget);
  });
}
