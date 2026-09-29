import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/data_refresh_service.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/transaction/controllers/transaction_form_controller.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime(2026, 9, 29, 12);

class _Transactions implements TransactionRepository {
  final inserted = <TransactionModel>[];
  final updated = <TransactionModel>[];

  @override
  Future<int> insert(TransactionModel transaction) async {
    inserted.add(transaction);
    return 1;
  }

  @override
  Future<void> update(TransactionModel transaction) async {
    updated.add(transaction);
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

void main() {
  late _Transactions repository;
  late TransactionFormController controller;

  setUp(() {
    repository = _Transactions();
    controller = TransactionFormController(repository, _Categories());
  });

  tearDown(Get.reset);

  test('formulir baru memuat kategori dan memilih yang pertama', () async {
    await controller.startNew();
    expect(controller.availableCategories.map((c) => c.id).toList(), [1, 2]);
    expect(controller.categoryId.value, 1);
    expect(controller.type.value, TransactionType.expense);
  });

  test('mengganti jenis memilih kategori pemasukan', () async {
    await controller.startNew();
    controller.setType(TransactionType.income);
    expect(controller.categoryId.value, 3);
  });

  test('tanpa nominal ditolak dengan pesan', () async {
    await controller.startNew();
    expect(await controller.save(), isFalse);
    expect(controller.error.value, 'Nominal harus lebih dari nol.');
    expect(repository.inserted, isEmpty);
  });

  test('menyimpan memakai nama kategori bila judul kosong dan memberi sinyal',
      () async {
    final refresh = Get.put(DataRefreshService());
    await controller.startNew();
    for (final key in ['4', '5', '000']) {
      controller.pressKey(key);
    }
    expect(controller.amount, 45000);

    expect(await controller.save(), isTrue);
    final saved = repository.inserted.single;
    expect(saved.amount, 45000);
    expect(saved.title, 'Makanan');
    expect(saved.categoryId, 1);
    expect(saved.note, isNull);
    expect(refresh.version.value, 1);
  });

  test('judul dan catatan diisi pengguna dipakai apa adanya', () async {
    await controller.startNew();
    controller.pressKey('9');
    controller.title.value = '  Makan siang  ';
    controller.note.value = 'bersama tim';
    expect(await controller.save(), isTrue);
    expect(repository.inserted.single.title, 'Makan siang');
    expect(repository.inserted.single.note, 'bersama tim');
  });

  test('tanggal boleh mundur tetapi tidak ke masa depan', () async {
    await controller.startNew();
    controller.setDate(DateTime(2020, 1, 5));
    expect(controller.date.value, DateTime(2020, 1, 5));

    controller.setDate(DateTime.now().add(const Duration(days: 30)));
    final today = DateTime.now();
    expect(
      controller.date.value,
      DateTime(today.year, today.month, today.day),
    );
  });

  test('mengedit memperbarui transaksi yang sama dan mempertahankan data lain',
      () async {
    final original = TransactionModel(
      id: 7,
      type: TransactionType.expense,
      title: 'Warung',
      amount: 25000,
      transactionDate: DateTime(2026, 9, 20, 13, 30),
      categoryId: 2,
      merchantOrSource: 'Warung Bu Ani',
      paymentMethod: PaymentMethod.qris,
      createdAt: DateTime(2026, 9, 20),
      updatedAt: DateTime(2026, 9, 20),
    );
    await controller.startEdit(original);
    expect(controller.isEditing, isTrue);
    expect(controller.amountDigits.value, '25000');

    controller.pressKey('⌫');
    controller.pressKey('0');
    expect(await controller.save(), isTrue);

    expect(repository.inserted, isEmpty);
    final updated = repository.updated.single;
    expect(updated.id, 7);
    expect(updated.merchantOrSource, 'Warung Bu Ani');
    expect(updated.paymentMethod, PaymentMethod.qris);
    expect(updated.transactionDate, DateTime(2026, 9, 20, 13, 30));
    expect(updated.createdAt, DateTime(2026, 9, 20));
  });
}
