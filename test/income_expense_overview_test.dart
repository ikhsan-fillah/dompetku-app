import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/report/widgets/report_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int income,
  required int expense,
  int previousIncome = 0,
  int previousExpense = 0,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: IncomeExpenseOverview(
            income: income,
            expense: expense,
            previousIncome: previousIncome,
            previousExpense: previousExpense,
            previousLabel: 'Sep',
            money: (v) => 'Rp $v',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('persen tersisa dan perbandingan bulan lalu', (tester) async {
    await _pump(
      tester,
      income: 5000000,
      expense: 1600000,
      previousIncome: 4000000,
      previousExpense: 2000000,
    );

    expect(find.text('68%'), findsOneWidget);
    expect(find.text('pemasukan tersisa bulan ini'), findsOneWidget);
    expect(find.text('terpakai 32%'), findsOneWidget);
    expect(find.text('tersisa 68%'), findsOneWidget);
    // Pemasukan naik 25%, pengeluaran turun 20%.
    expect(find.text('▲ 25% dari Sep'), findsOneWidget);
    expect(find.text('▼ 20% dari Sep'), findsOneWidget);
    expect(find.text('+ Rp 3400000'), findsOneWidget);
  });

  testWidgets('pengeluaran melebihi pemasukan ditandai merah', (tester) async {
    await _pump(tester, income: 1000000, expense: 1500000);

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('pengeluaran melebihi pemasukan'), findsOneWidget);
    expect(find.text('belum ada data Sep'), findsNWidgets(2));
    expect(find.text('− Rp 500000'), findsOneWidget);
  });

  testWidgets('bulan tanpa transaksi tidak error', (tester) async {
    await _pump(tester, income: 0, expense: 0);

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('belum ada transaksi bulan ini'), findsOneWidget);
  });
}
