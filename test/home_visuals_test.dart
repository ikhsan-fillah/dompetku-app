import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/dashboard/models/dashboard_view_models.dart';
import 'package:dompetku_app/features/dashboard/models/expense_slice.dart';
import 'package:dompetku_app/features/dashboard/widgets/budget_ring.dart';
import 'package:dompetku_app/features/dashboard/widgets/expense_donut.dart';
import 'package:dompetku_app/features/dashboard/widgets/spending_bars.dart';
import 'package:dompetku_app/features/home/widgets/period_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

ExpenseSlice _slice(int id, String name, int amount, double percent) {
  return ExpenseSlice(
    categoryId: id,
    name: name,
    colorValue: 0xFFE57373,
    amount: amount,
    percent: percent,
  );
}

void main() {
  testWidgets('donat menampilkan legenda berurutan beserta persen bulat', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ExpenseDonut(
          slices: [
            _slice(1, 'Makanan', 600, 60),
            _slice(2, 'Belanja', 300, 30),
            _slice(3, 'Tagihan', 100, 10),
          ],
        ),
      ),
    );

    expect(find.text('60%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    final first = tester.getTopLeft(find.text('Makanan')).dy;
    final second = tester.getTopLeft(find.text('Belanja')).dy;
    final third = tester.getTopLeft(find.text('Tagihan')).dy;
    expect(first, lessThan(second));
    expect(second, lessThan(third));
  });

  testWidgets('mengetuk legenda menampilkan detail kategori di tengah', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ExpenseDonut(
          slices: [
            _slice(1, 'Makanan', 600, 60),
            _slice(2, 'Belanja', 300, 30),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Belanja'));
    await tester.pump();
    expect(find.text('Total'), findsNothing);
  });

  testWidgets('donat tanpa data menampilkan pesan', (tester) async {
    await tester.pumpWidget(_host(const ExpenseDonut(slices: [])));
    expect(
      find.text('Belum ada pengeluaran pada periode ini.'),
      findsOneWidget,
    );
  });

  testWidgets('cincin anggaran menampilkan persen bulat', (tester) async {
    await tester.pumpWidget(
      _host(const BudgetRing(percent: 73, color: Colors.teal)),
    );
    expect(find.text('73%'), findsOneWidget);
  });

  testWidgets('cincin anggaran di atas 100 persen tidak error', (tester) async {
    await tester.pumpWidget(
      _host(const BudgetRing(percent: 140, color: Colors.red)),
    );
    expect(find.text('140%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mengetuk batang menampilkan nilai persisnya', (tester) async {
    final buckets = [
      for (var i = 1; i <= 3; i++)
        TrendBucket(
          label: '$i',
          start: DateTime(2026, 9, i),
          end: DateTime(2026, 9, i),
          amount: i * 100,
        ),
    ];
    await tester.pumpWidget(_host(SpendingBars(buckets: buckets)));
    expect(find.text('Ketuk batang untuk melihat nilai'), findsOneWidget);

    final bars = find.descendant(
      of: find.byType(SpendingBars),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(bars.at(1));
    await tester.pump();
    expect(find.textContaining('Rp 200'), findsOneWidget);
  });

  testWidgets('chip periode memanggil onSelect dengan preset yang dipilih', (
    tester,
  ) async {
    DateRangePreset? picked;
    await tester.pumpWidget(
      _host(
        PeriodChips(
          selected: DateRangePreset.month,
          onSelect: (preset) => picked = preset,
        ),
      ),
    );

    await tester.tap(find.text('3 Bulan'));
    expect(picked, DateRangePreset.threeMonths);
    await tester.tap(find.text('Hari ini'));
    expect(picked, DateRangePreset.today);
  });
}
