import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/drafts/controllers/draft_controller.dart';
import 'package:dompetku_app/features/drafts/models/draft_model.dart';
import 'package:dompetku_app/features/drafts/pages/drafts_page.dart';
import 'package:dompetku_app/features/drafts/repositories/draft_repository.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final _now = DateTime.utc(2026);

class _Drafts implements DraftRepository {
  _Drafts(this.items);

  final List<DraftModel> items;

  @override
  Future<List<DraftModel>> getPending() async => List.of(items);

  @override
  Future<void> update(DraftModel draft) async {}

  @override
  Future<void> setStatus(int id, DraftStatus status) async =>
      items.removeWhere((d) => d.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tx implements TransactionRepository {
  final inserted = <TransactionModel>[];

  @override
  Future<int> insert(TransactionModel transaction) async {
    inserted.add(transaction);
    return inserted.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async => [
    CategoryModel(
      id: 7,
      name: 'Transport',
      type: TransactionType.expense,
      iconKey: 'car',
      colorValue: 0xFF3B6EA8,
      isDefault: false,
      isFavorite: false,
      sortOrder: 0,
      isArchived: false,
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DraftModel _draft(int id, {int? categoryId}) => DraftModel(
  id: id,
  source: 'GoPay',
  kind: TransactionType.expense,
  amount: 25000,
  merchant: 'Ojek $id',
  categoryId: categoryId,
  detectedAt: DateTime(2026, 10, 3, 14, 5),
  dedupeKey: 'k$id',
);

Future<_Tx> _open(WidgetTester tester, List<DraftModel> drafts) async {
  final tx = _Tx();
  Get.put(DraftController(_Drafts(drafts), tx, categories: _Categories()));
  await tester.pumpWidget(
    GetMaterialApp(theme: AppTheme.light, home: const DraftsPage()),
  );
  await tester.runAsync(pumpEventQueue);
  await tester.pumpAndSettle();
  return tx;
}

void main() {
  tearDown(Get.reset);

  testWidgets('kartu menampilkan tanggal dan jam notifikasi terbaca', (
    tester,
  ) async {
    await _open(tester, [_draft(1, categoryId: 7)]);

    expect(find.textContaining('3 Okt 2026 · 14.05'), findsOneWidget);
    // Satu draf: tombol Konfirmasi semua belum perlu.
    expect(find.text('Konfirmasi semua'), findsNothing);
  });

  testWidgets('Konfirmasi semua ada di app bar saat draf lebih dari satu', (
    tester,
  ) async {
    final tx = await _open(tester, [
      _draft(1, categoryId: 7),
      _draft(2, categoryId: 7),
    ]);

    await tester.tap(find.text('Konfirmasi semua'));
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tx.inserted, hasLength(2));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('Edit memilih kategori di dialog yang sama, tanpa lembar lain', (
    tester,
  ) async {
    final tx = await _open(tester, [_draft(1)]);

    await tester.tap(find.text('Edit'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(find.text('Ubah draf'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    // Simpan nonaktif sebelum kategori dipilih.
    await tester.tap(find.text('Simpan & konfirmasi'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah draf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('category-choice-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan & konfirmasi'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(tx.inserted.single.categoryId, 7);
    expect(tx.inserted.single.transactionDate, DateTime(2026, 10, 3, 14, 5));
  });
}
