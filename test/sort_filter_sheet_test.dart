import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/sort_chip.dart';
import 'package:dompetku_app/core/widgets/sort_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

enum _Sort { newest, largest }

const _categories = [
  FilterCategory(
    id: 1,
    name: 'Makan',
    iconKey: 'utensils',
    color: Colors.orange,
  ),
  FilterCategory(id: 2, name: 'Transport', iconKey: 'car', color: Colors.blue),
  FilterCategory(
    id: 3,
    name: 'Gaji',
    iconKey: 'wallet',
    color: Colors.green,
    isIncome: true,
  ),
];

/// Memasang app lalu membuka lembar; hasilnya selesai saat lembar ditutup.
Future<Future<SortFilterValue<_Sort>?>> _open(
  WidgetTester tester, {
  SortFilterValue<_Sort> value = const SortFilterValue(sort: _Sort.newest),
  Future<int?> Function(SortFilterValue<_Sort>)? countFor,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  final result = showSortFilterSheet<_Sort>(
    context,
    value: value,
    defaultSort: _Sort.newest,
    sortOptions: _Sort.values,
    sortLabel: (s) => s == _Sort.newest ? 'Terbaru' : 'Terbesar',
    categories: _categories,
    countFor: countFor,
  );
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('memilih urutan dan kategori ikon lalu menerapkan', (
    tester,
  ) async {
    final future = await _open(
      tester,
      countFor: (v) async => v.categoryIds.length * 3,
    );

    expect(find.text('Urutkan & saring'), findsOneWidget);
    // Nama kategori selalu tampil di bawah ikonnya.
    expect(find.text('Makan'), findsOneWidget);
    expect(find.text('Semua kategori'), findsNothing);
    // Pengeluaran dan pemasukan di baris terpisah.
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);

    await tester.tap(find.text('Terbesar'));
    await tester.tap(find.byKey(const ValueKey('filter-category-2')));
    // Jumlah hasil dihitung ulang setelah jeda singkat.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Tampilkan 3 hasil'), findsOneWidget);
    await tester.ensureVisible(find.text('Tampilkan 3 hasil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan 3 hasil'));
    await tester.pumpAndSettle();

    final result = await future;
    expect(result?.sort, _Sort.largest);
    expect(result?.categoryIds, {2});
    expect(result?.activeCount, 1);
  });

  testWidgets('Reset mengosongkan saringan dan urutan bawaan', (tester) async {
    final future = await _open(
      tester,
      value: const SortFilterValue(
        sort: _Sort.largest,
        categoryIds: {1},
        minAmount: 10000,
      ),
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Terapkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    final result = await future;
    expect(result?.sort, _Sort.newest);
    expect(result?.categoryIds, isEmpty);
    expect(result?.minAmount, isNull);
    expect(result?.activeCount, 0);
  });

  testWidgets('chip menampilkan lencana jumlah saringan aktif', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SortFilterChip(
              label: 'Terbaru',
              activeCount: 2,
              tooltip: 'Urutkan & saring',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('Urutkan & saring (2)'), findsOneWidget);
  });
}
