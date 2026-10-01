import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/receipt/services/receipt_ocr_service.dart';
import 'package:dompetku_app/features/transaction/controllers/transaction_form_controller.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/transaction/widgets/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime(2026, 9, 29, 12);

class _Transactions implements TransactionRepository {
  final inserted = <TransactionModel>[];

  @override
  Future<int> insert(TransactionModel transaction) async {
    inserted.add(transaction);
    return 1;
  }

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async => [];

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

class _NoopReceiptTextRecognizer implements ReceiptTextRecognizer {
  @override
  Future<String> recognize(String imagePath) async => '';

  @override
  Future<void> dispose() async {}
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

Future<_Transactions> _openSheet(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(500, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repository = _Transactions();
  Get.put(
    TransactionFormController(
      repository,
      _Categories(),
      ocr: ReceiptOcrService(_NoopReceiptTextRecognizer()),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showTransactionSheet(context),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka'));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('sheet baru menampilkan judul, nominal nol, dan kategori', (
    tester,
  ) async {
    await _openSheet(tester);
    expect(find.text('Tambah transaksi'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Transportasi'), findsOneWidget);
    expect(find.text('Gaji'), findsNothing);
  });

  testWidgets('keypad mengisi nominal lalu simpan menutup sheet', (
    tester,
  ) async {
    final repository = await _openSheet(tester);
    final five = find.text('5');
    final thousand = find.text('000');
    final save = find.text('Simpan transaksi');

    await _reveal(tester, five);
    await tester.tap(five);
    await _reveal(tester, thousand);
    await tester.tap(thousand);
    await tester.pump();
    expect(find.text('Rp 5.000'), findsOneWidget);

    await _reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.inserted.single.amount, 5000);
    expect(repository.inserted.single.title, 'Makanan');
    expect(find.text('Tambah transaksi'), findsNothing);
    expect(find.text('Transaksi tersimpan.'), findsOneWidget);
  });

  testWidgets(
    'simpan tanpa nominal menampilkan pesan dan sheet tetap terbuka',
    (tester) async {
      final repository = await _openSheet(tester);
      final save = find.text('Simpan transaksi');

      await _reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('Nominal harus lebih dari nol.'), findsOneWidget);
      expect(find.text('Tambah transaksi'), findsOneWidget);
      expect(repository.inserted, isEmpty);
    },
  );

  testWidgets('memilih Pemasukan mengganti daftar kategori', (tester) async {
    await _openSheet(tester);

    await tester.tap(find.text('Pemasukan'));
    await tester.pump();

    expect(find.text('Gaji'), findsOneWidget);
    expect(find.text('Makanan'), findsNothing);
  });
}
