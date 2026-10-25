import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/recap/pages/recaps_page.dart';
import 'package:dompetku_app/features/recap/services/month_palette.dart';
import 'package:dompetku_app/features/recap/services/recap_calculation_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Transactions implements TransactionRepository {
  _Transactions(this.items);

  final List<TransactionModel> items;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TransactionModel _expense(int amount, DateTime date) => TransactionModel(
  type: TransactionType.expense,
  title: 'T',
  amount: amount,
  transactionDate: date,
  categoryId: 1,
  createdAt: date,
  updatedAt: date,
);

void main() {
  group('MonthPalette', () {
    test('tetap sama setiap dibaca', () {
      expect(MonthPalette.of(2026, 10), MonthPalette.of(2026, 10));
    });

    test('beda dari bulan sebelumnya dan bulan yang sama tahun lalu', () {
      for (var year = 2001; year <= 2040; year++) {
        for (var month = 1; month <= 12; month++) {
          final color = MonthPalette.of(year, month);
          final previous = month == 1
              ? MonthPalette.of(year - 1, 12)
              : MonthPalette.of(year, month - 1);
          expect(color, isNot(previous), reason: '$year-$month');
          expect(
            color,
            isNot(MonthPalette.of(year - 1, month)),
            reason: '$year-$month vs tahun lalu',
          );
        }
      }
    });

    test('memakai banyak warna, bukan dua-tiga saja', () {
      final used = {
        for (var m = 1; m <= 12; m++) MonthPalette.of(2026, m),
        for (var m = 1; m <= 12; m++) MonthPalette.of(2027, m),
      };
      expect(used.length, greaterThanOrEqualTo(8));
    });
  });

  testWidgets('cerita, ringkasan, dan kartu bulan dengan perubahan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    // Dua bulan terakhir dalam tahun berjalan (atau Jan-Feb bila Januari).
    final second = now.month >= 2 ? now.month : 2;
    final first = second - 1;
    final year = now.month >= 2 ? now.year : now.year - 1;
    Get.put(const RecapCalculationService(FinancialCalculationService()));
    Get.put<TransactionRepository>(
      _Transactions([
        _expense(1000000, DateTime(year, first, 5)),
        _expense(1500000, DateTime(year, second, 1)),
      ]),
    );
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const RecapsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Rata-rata'), findsOneWidget);
    expect(find.text('Terbesar'), findsOneWidget);
    expect(find.text('2,5 jt'), findsOneWidget);
    // Bulan kedua naik 50% dari bulan pertama.
    expect(find.text('▲ 50%'), findsOneWidget);
    expect(find.text('Putar'), findsWidgets);
    // Kartu rekap tahunan ada di ujung kanan kartu cerita.
    await tester.drag(find.text('Putar').first, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('TAHUNAN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
