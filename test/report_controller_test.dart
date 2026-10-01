import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/report/controllers/report_controller.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository(this.items);

  List<TransactionModel> items;
  bool fail = false;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async {
    if (fail) throw StateError('db error');
    return items;
  }

  @override
  Future<TransactionModel?> getById(int id) => throw UnimplementedError();

  @override
  Future<int> insert(TransactionModel transaction) =>
      throw UnimplementedError();

  @override
  Future<void> update(TransactionModel transaction) =>
      throw UnimplementedError();

  @override
  Future<void> delete(int id) => throw UnimplementedError();

  @override
  Future<List<TransactionModel>> getByCategory(int categoryId) =>
      throw UnimplementedError();

  @override
  Future<int> getTotal({required TransactionType type, DateRange? range}) =>
      throw UnimplementedError();
}

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this.items);

  List<CategoryModel> items;
  bool fail = false;

  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async {
    if (fail) throw StateError('db error');
    return items;
  }

  @override
  Future<CategoryModel?> getById(int id) => throw UnimplementedError();

  @override
  Future<int> insert(CategoryModel category) => throw UnimplementedError();

  @override
  Future<void> update(CategoryModel category) => throw UnimplementedError();

  @override
  Future<void> archive(int id) => throw UnimplementedError();

  @override
  Future<void> reorder(List<int> orderedIds) => throw UnimplementedError();
}

TransactionModel _tx(
  TransactionType type,
  int amount,
  DateTime date, {
  int categoryId = 1,
}) =>
    TransactionModel(
      type: type,
      title: 'Transaksi',
      amount: amount,
      transactionDate: date,
      categoryId: categoryId,
      createdAt: date,
      updatedAt: date,
    );

CategoryModel _category({
  required int id,
  required String name,
  required int colorValue,
}) {
  final now = DateTime(2026, 1, 1);
  return CategoryModel(
    id: id,
    name: name,
    type: TransactionType.expense,
    iconKey: 'category',
    colorValue: colorValue,
    isDefault: false,
    isFavorite: false,
    sortOrder: id,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final september = DateRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 30),
  );

  late _FakeTransactionRepository transactions;
  late _FakeCategoryRepository categories;
  late ReportController controller;

  setUp(() {
    transactions = _FakeTransactionRepository([]);
    categories = _FakeCategoryRepository([]);
    controller = ReportController(
      transactions,
      categories,
      const FinancialCalculationService(),
    );
  });

  test('state awal idle dengan rentang bulan berjalan', () {
    final month = DateRange.fromPreset(DateRangePreset.month);
    expect(controller.state.value.status, ResourceStatus.idle);
    expect(controller.range.value.start, month.start);
    expect(controller.range.value.end, month.end);
  });

  test('load menyimpan rentang yang dipilih', () async {
    await controller.load(september);
    expect(controller.range.value.start, september.start);
    expect(controller.range.value.end, september.end);
  });

  test('empty bila tidak ada transaksi pada rentang', () async {
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.empty);
  });

  test('success menghitung ringkasan dan kategori secara menurun', () async {
    categories.items = [
      _category(id: 1, name: 'Makan', colorValue: 0xFF10B981),
      _category(id: 2, name: 'Transportasi', colorValue: 0xFFF43F5E),
    ];
    transactions.items = [
      _tx(TransactionType.income, 5000000, DateTime(2026, 9, 1, 8)),
      _tx(TransactionType.expense, 120000, DateTime(2026, 9, 10, 12)),
      _tx(
        TransactionType.expense,
        30000,
        DateTime(2026, 9, 30, 20),
        categoryId: 2,
      ),
    ];
    await controller.load(september);
    final report = controller.state.value.data!;
    expect(controller.state.value.status, ResourceStatus.success);
    expect(report.summary.income, 5000000);
    expect(report.summary.expense, 150000);
    expect(report.summary.balance, 4850000);
    expect(report.expensesByCategory, hasLength(2));
    expect(report.expensesByCategory.first.name, 'Makan');
    expect(report.expensesByCategory.first.amount, 120000);
    expect(report.expensesByCategory.last.name, 'Transportasi');
    expect(report.expensesByCategory.last.amount, 30000);
  });

  test('kategori yang tidak tersedia tetap tampil dalam laporan', () async {
    transactions.items = [
      _tx(TransactionType.expense, 100000, DateTime(2026, 9, 15), categoryId: 9),
    ];
    await controller.load(september);
    final item = controller.state.value.data!.expensesByCategory.single;
    expect(item.categoryId, 9);
    expect(item.name, 'Kategori diarsipkan');
    expect(item.colorValue, 0xFF64748B);
  });

  test('membandingkan pengeluaran dengan periode sebelumnya yang setara', () async {
    transactions.items = [
      _tx(TransactionType.expense, 150000, DateTime(2026, 9, 10)),
      _tx(TransactionType.expense, 100000, DateTime(2026, 8, 10)),
    ];
    await controller.load(
      DateRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
    );
    expect(controller.state.value.data!.expenseChange, 0.5);
  });

  test('transaksi di luar rentang tidak ikut dihitung', () async {
    transactions.items = [
      _tx(TransactionType.expense, 100000, DateTime(2026, 9, 15, 9)),
      _tx(TransactionType.expense, 900000, DateTime(2026, 8, 31, 23)),
      _tx(TransactionType.income, 700000, DateTime(2026, 10, 1, 1)),
    ];
    await controller.load(september);
    final report = controller.state.value.data!;
    expect(report.summary.income, 0);
    expect(report.summary.expense, 100000);
    expect(report.summary.balance, -100000);
  });

  test('error bila salah satu repository gagal', () async {
    transactions.fail = true;
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.error);
    expect(controller.state.value.message, 'Gagal memuat laporan.');

    transactions.fail = false;
    transactions.items = [
      _tx(TransactionType.income, 200000, DateTime(2026, 9, 5, 10)),
    ];
    categories.fail = true;
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.error);
  });

  test('load ulang setelah error dapat berhasil', () async {
    transactions.fail = true;
    await controller.load(september);
    transactions.fail = false;
    transactions.items = [
      _tx(TransactionType.income, 200000, DateTime(2026, 9, 5, 10)),
    ];
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.success);
    expect(controller.state.value.data!.summary.income, 200000);
  });

  test('statistik belanja: rata-rata harian, hari terbesar, merchant teratas', () async {
    transactions.items = [
      _tx(TransactionType.expense, 100000, DateTime(2026, 9, 10), categoryId: 1),
      _tx(TransactionType.expense, 200000, DateTime(2026, 9, 15)),
      _tx(TransactionType.expense, 50000, DateTime(2026, 9, 20)),
    ];
    await controller.load(september);
    final report = controller.state.value.data!;
    expect(report.dailyAverage, closeTo(350000 / 30, 0.5));
    expect(report.highestSpendingDay, DateTime(2026, 9, 15));
    expect(report.highestSpendingDayAmount, 200000);
    expect(report.topMerchant, 'Transaksi');
    expect(report.topMerchantCount, 3);
  });

  test('statistik belanja menghitung merchant dari merchantOrSource', () async {
    TransactionModel merchantTx(
      int amount,
      DateTime date,
      String merchant,
    ) => TransactionModel(
      type: TransactionType.expense,
      title: 'Transaksi',
      amount: amount,
      transactionDate: date,
      categoryId: 1,
      merchantOrSource: merchant,
      createdAt: date,
      updatedAt: date,
    );
    transactions.items = [
      merchantTx(50000, DateTime(2026, 9, 5), 'Kopi Kenangan'),
      merchantTx(60000, DateTime(2026, 9, 12), 'Kopi Kenangan'),
      merchantTx(20000, DateTime(2026, 9, 20), 'Warung Bu Ani'),
    ];
    await controller.load(september);
    final report = controller.state.value.data!;
    expect(report.topMerchant, 'Kopi Kenangan');
    expect(report.topMerchantCount, 2);
  });
}
