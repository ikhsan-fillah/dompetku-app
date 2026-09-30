import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
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

TransactionModel _tx(TransactionType type, int amount, DateTime date) =>
    TransactionModel(
      type: type,
      title: 'Transaksi',
      amount: amount,
      transactionDate: date,
      categoryId: 1,
      createdAt: date,
      updatedAt: date,
    );

void main() {
  final september = DateRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 30),
  );

  late _FakeTransactionRepository repository;
  late ReportController controller;

  setUp(() {
    repository = _FakeTransactionRepository([]);
    controller = ReportController(
      repository,
      const FinancialCalculationService(),
    );
  });

  test('state awal idle dengan rentang bulan berjalan', () {
    final month = DateRange.fromPreset(DateRangePreset.month);
    expect(controller.state.value.status, ResourceStatus.idle);
    expect(controller.range.value.start, month.start);
    expect(controller.range.value.end, month.end);
  });

  test('load menandai loading sebelum data selesai dimuat', () async {
    final future = controller.load(september);
    expect(controller.state.value.status, ResourceStatus.loading);
    await future;
  });

  test('load menyimpan rentang yang dipilih', () async {
    await controller.load(september);
    expect(controller.range.value.start, september.start);
    expect(controller.range.value.end, september.end);
  });

  test('empty bila tidak ada transaksi', () async {
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.empty);
  });

  test('empty bila semua transaksi berada di luar rentang', () async {
    repository.items = [
      _tx(TransactionType.expense, 50000, DateTime(2026, 8, 31, 12)),
    ];
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.empty);
  });

  test('success menghitung pemasukan, pengeluaran, dan saldo', () async {
    repository.items = [
      _tx(TransactionType.income, 5000000, DateTime(2026, 9, 1, 8)),
      _tx(TransactionType.expense, 120000, DateTime(2026, 9, 10, 12)),
      _tx(TransactionType.expense, 30000, DateTime(2026, 9, 30, 20)),
    ];
    await controller.load(september);
    final summary = controller.state.value.data!;
    expect(controller.state.value.status, ResourceStatus.success);
    expect(summary.income, 5000000);
    expect(summary.expense, 150000);
    expect(summary.balance, 4850000);
  });

  test('transaksi di luar rentang tidak ikut dihitung', () async {
    repository.items = [
      _tx(TransactionType.expense, 100000, DateTime(2026, 9, 15, 9)),
      _tx(TransactionType.expense, 900000, DateTime(2026, 8, 31, 23)),
      _tx(TransactionType.income, 700000, DateTime(2026, 10, 1, 1)),
    ];
    await controller.load(september);
    final summary = controller.state.value.data!;
    expect(summary.income, 0);
    expect(summary.expense, 100000);
    expect(summary.balance, -100000);
  });

  test('error bila repository gagal', () async {
    repository.fail = true;
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.error);
    expect(controller.state.value.message, 'Gagal memuat laporan.');
  });

  test('load ulang setelah error dapat berhasil', () async {
    repository.fail = true;
    await controller.load(september);
    repository.fail = false;
    repository.items = [
      _tx(TransactionType.income, 200000, DateTime(2026, 9, 5, 10)),
    ];
    await controller.load(september);
    expect(controller.state.value.status, ResourceStatus.success);
    expect(controller.state.value.data!.income, 200000);
  });
}
