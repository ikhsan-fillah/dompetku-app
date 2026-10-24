import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/backup/services/excel_export.dart';
import 'package:dompetku_app/features/budget/models/budget_model.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryModel _category(int id, String name, TransactionType type) =>
    CategoryModel(
      id: id,
      name: name,
      type: type,
      iconKey: 'tag',
      colorValue: 0xFF000000,
      isDefault: false,
      isFavorite: false,
      sortOrder: id,
      isArchived: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

TransactionModel _tx(
  String title,
  int amount,
  TransactionType type,
  int category,
  int day,
) => TransactionModel(
  type: type,
  title: title,
  amount: amount,
  transactionDate: DateTime(2026, 10, day),
  categoryId: category,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  final categories = {
    1: _category(1, 'Gaji', TransactionType.income),
    2: _category(2, 'Makan', TransactionType.expense),
    3: _category(3, 'Transport', TransactionType.expense),
  };
  final transactions = [
    _tx('Gaji Oktober', 5000000, TransactionType.income, 1, 1),
    _tx('Makan siang', 45000, TransactionType.expense, 2, 3),
    _tx('Ojek', 25000, TransactionType.expense, 3, 4),
    _tx('Makan malam', 30000, TransactionType.expense, 2, 5),
  ];
  final budget = BudgetModel(
    id: 1,
    name: 'Makan',
    amountLimit: 1000000,
    categoryId: 2,
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 10, 31),
    isArchived: false,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  List<int> build() => const ExcelWorkbookBuilder().build(
    title: 'Tally · Transaksi Oktober 2026',
    range: DateRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
    exportedAt: DateTime(2026, 10, 22, 14, 40),
    transactions: transactions,
    categories: categories,
    budgets: [BudgetUsage(budget, 75000)],
  );

  test('tiga lembar, nominal sebagai angka, total dan saldo', () {
    final bytes = build();
    final dump = Platform.environment['TALLY_XLSX_DUMP'];
    if (dump != null) File(dump).writeAsBytesSync(bytes);

    final excel = Excel.decodeBytes(bytes);
    expect(excel.tables.keys, ['Transaksi', 'Per kategori', 'Anggaran']);

    final sheet = excel['Transaksi'];
    expect(
      sheet.cell(CellIndex.indexByString('A1')).value.toString(),
      'Tally · Transaksi Oktober 2026',
    );
    expect(
      sheet.cell(CellIndex.indexByString('A4')).value.toString(),
      'Tanggal',
    );
    expect(
      sheet.cell(CellIndex.indexByString('E5')).value,
      isA<IntCellValue>(),
    );
    // Baris 9: total; baris 10: saldo.
    expect(
      (sheet.cell(CellIndex.indexByString('E9')).value as IntCellValue).value,
      5000000,
    );
    expect(
      (sheet.cell(CellIndex.indexByString('F9')).value as IntCellValue).value,
      100000,
    );
    expect(
      (sheet.cell(CellIndex.indexByString('F10')).value as IntCellValue).value,
      4900000,
    );

    final perCategory = excel['Per kategori'];
    expect(
      perCategory.cell(CellIndex.indexByString('A6')).value.toString(),
      'Makan',
    );
  });

  test('baris kepala dibekukan di setiap lembar', () {
    final archive = ZipDecoder().decodeBytes(build());
    final sheets = archive.files.where(
      (f) => f.name.startsWith('xl/worksheets/sheet'),
    );
    expect(sheets, hasLength(3));
    for (final file in sheets) {
      final xml = utf8.decode(file.content as List<int>);
      expect(xml, contains('state="frozen"'), reason: file.name);
      expect(xml, contains('ySplit="4"'));
    }
  });
}
