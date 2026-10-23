import 'package:dompetku_app/core/theme/app_colors.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_bar_icon_button.dart';
import 'package:dompetku_app/core/widgets/sort_chip.dart';
import 'package:dompetku_app/features/budget/services/budget_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _Order { newest, oldest, largest }

const _chip = {
  _Order.newest: 'Terbaru',
  _Order.oldest: 'Terlama',
  _Order.largest: 'Terbesar',
};
const _menu = {
  _Order.newest: 'Terbaru',
  _Order.oldest: 'Terlama',
  _Order.largest: 'Nominal terbesar',
};

void main() {
  Future<List<_Order>> open(
    WidgetTester tester, {
    _Order value = _Order.newest,
    double width = 390,
  }) async {
    final picked = <_Order>[];
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: SortChip<_Order>(
              value: value,
              options: _Order.values,
              chipLabel: (o) => _chip[o]!,
              menuLabel: (o) => _menu[o]!,
              onSelected: picked.add,
              tooltip: 'Urutkan',
            ),
          ),
        ),
      ),
    );
    return picked;
  }

  testWidgets('chip menampilkan ikon urut dan label singkat pilihan aktif', (
    tester,
  ) async {
    await open(tester, value: _Order.largest);

    expect(find.text('Terbesar'), findsOneWidget);
    expect(find.text('Nominal terbesar'), findsNothing);
    expect(find.byIcon(LucideIcons.arrowUpDown), findsOneWidget);
  });

  testWidgets('mengetuk chip membuka menu dengan label lengkap', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byType(SortChip<_Order>));
    await tester.pumpAndSettle();

    expect(find.text('Nominal terbesar'), findsOneWidget);
    expect(find.text('Terlama'), findsOneWidget);
  });

  testWidgets('memilih baris memanggil onSelected dan menutup menu', (
    tester,
  ) async {
    final picked = await open(tester);

    await tester.tap(find.byType(SortChip<_Order>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nominal terbesar'));
    await tester.pumpAndSettle();

    expect(picked, [_Order.largest]);
    expect(find.text('Nominal terbesar'), findsNothing);
  });

  testWidgets('label panjang dipotong dan tidak overflow di layar sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: SortChip<int>(
              value: 1,
              options: const [1],
              chipLabel: (_) => 'Label yang sangat sangat panjang sekali',
              menuLabel: (_) => 'x',
              onSelected: (_) {},
              tooltip: 'Urutkan',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('chip sama dengan tombol ikon app bar: garis, latar, tinggi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              SortChip<_Order>(
                value: _Order.newest,
                options: _Order.values,
                chipLabel: (o) => _chip[o]!,
                menuLabel: (o) => _menu[o]!,
                onSelected: (_) {},
                tooltip: 'Urutkan',
              ),
              AppBarIconButton(
                icon: LucideIcons.archive,
                tooltip: 'Arsip',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final chip = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SortChip<_Order>),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border != null);
    final button =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(AppBarIconButton),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(chip.border, button.border);
    expect(chip.color, button.color);
    expect(chip.borderRadius, button.borderRadius);
    expect((chip.border as Border).top.color, AppColors.line);
  });

  test('anggaran punya semua urutan termasuk Nama Z-A', () {
    expect(BudgetSort.values, contains(BudgetSort.namaZA));
  });
}
