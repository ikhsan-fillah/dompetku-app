import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/dashboard/models/budget_progress_model.dart';
import 'package:dompetku_app/features/dashboard/models/dashboard_view_models.dart';
import 'package:dompetku_app/features/dashboard/models/expense_slice.dart';
import 'package:dompetku_app/features/home/widgets/budget_summary_cards.dart';
import 'package:dompetku_app/features/home/widgets/category_cards_grid.dart';
import 'package:dompetku_app/features/home/widgets/insight_banner.dart';
import 'package:dompetku_app/features/home/widgets/recent_transactions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: 360,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  ),
);

const _slice = ExpenseSlice(
  categoryId: 1,
  name: 'Makanan',
  colorValue: 0xFFE57373,
  amount: 1387000,
  percent: 38,
);

void main() {
  testWidgets('kartu anggaran menampilkan cincin, hari berjalan, dan sisa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        BudgetSummaryCards(
          budget: const BudgetProgressModel(
            name: 'September',
            limit: 5000000,
            used: 3650000,
            elapsedDays: 29,
            totalDays: 30,
          ),
          topCategory: _slice,
          onSetupBudget: () {},
        ),
      ),
    );

    expect(find.text('73%'), findsOneWidget);
    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Hari ke-29 dari 30'), findsOneWidget);
    expect(find.text('Sisa Rp 1.350.000'), findsOneWidget);
  });

  testWidgets('anggaran terlewati menampilkan status habis dan jumlah lewat', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        BudgetSummaryCards(
          budget: const BudgetProgressModel(
            name: 'September',
            limit: 1000000,
            used: 1200000,
            elapsedDays: 10,
            totalDays: 30,
          ),
          topCategory: null,
          onSetupBudget: () {},
        ),
      ),
    );

    expect(find.text('Habis'), findsOneWidget);
    expect(find.text('Lewat Rp 200.000'), findsOneWidget);
    expect(find.text('Belum ada data'), findsOneWidget);
  });

  testWidgets('tanpa anggaran menampilkan ajakan dan tombol Atur', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        BudgetSummaryCards(
          budget: null,
          topCategory: _slice,
          onSetupBudget: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Belum ada anggaran'), findsOneWidget);
    await tester.tap(find.text('Atur'));
    expect(tapped, isTrue);
  });

  testWidgets('kategori teratas menampilkan nama dan bagiannya', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        BudgetSummaryCards(
          budget: null,
          topCategory: _slice,
          onSetupBudget: () {},
        ),
      ),
    );

    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('38% dari pengeluaran'), findsOneWidget);
  });

  testWidgets('kartu kategori menampilkan semua item termasuk yang ganjil', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CategoryCardsGrid(
          items: [
            CategoryCardData(
              categoryId: 1,
              name: 'Makanan',
              iconKey: 'restaurant',
              colorValue: 0xFFE57373,
              amount: 1387000,
              sharePercent: 38,
            ),
            CategoryCardData(
              categoryId: 2,
              name: 'Transportasi',
              iconKey: 'directions_car',
              colorValue: 0xFF64B5F6,
              amount: 803000,
              sharePercent: 22,
            ),
            CategoryCardData(
              categoryId: 3,
              name: 'Belanja',
              iconKey: 'shopping_bag',
              colorValue: 0xFFBA68C8,
              amount: 657000,
              sharePercent: 18,
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Transportasi'), findsOneWidget);
    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Rp 1.387.000'), findsOneWidget);
  });

  testWidgets('transaksi terbaru menampilkan tanda nominal dan Lihat semua', (
    tester,
  ) async {
    var seeAll = false;
    await tester.pumpWidget(
      _host(
        RecentTransactionsCard(
          onSeeAll: () => seeAll = true,
          items: [
            RecentTransactionItem(
              id: 1,
              title: 'Warung Sederhana',
              categoryName: 'Makanan',
              iconKey: 'restaurant',
              colorValue: 0xFFE57373,
              amount: 45000,
              isIncome: false,
              date: DateTime(2026, 9, 28),
            ),
            RecentTransactionItem(
              id: 2,
              title: 'Gaji',
              categoryName: 'Gaji',
              iconKey: 'payments',
              colorValue: 0xFF43A047,
              amount: 5000000,
              isIncome: true,
              date: DateTime(2026, 9, 25),
            ),
          ],
        ),
      ),
    );

    expect(find.text('− Rp 45.000'), findsOneWidget);
    expect(find.text('+ Rp 5.000.000'), findsOneWidget);
    expect(find.text('Makanan · 28 Sep 2026'), findsOneWidget);
    await tester.tap(find.text('Lihat semua'));
    expect(seeAll, isTrue);
  });

  testWidgets('banner insight menampilkan pesan', (tester) async {
    await tester.pumpWidget(
      _host(
        const InsightBanner(
          message: 'Makanan naik 18% dibanding periode sebelumnya',
        ),
      ),
    );
    expect(
      find.text('Makanan naik 18% dibanding periode sebelumnya'),
      findsOneWidget,
    );
  });
}
