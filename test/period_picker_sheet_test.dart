import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/home/widgets/period_picker_sheet.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Transactions implements TransactionRepository {
  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(Get.reset);

  testWidgets('semua periode bekas chip tersedia di pemilih tanggal app bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = Get.put(
      DashboardController(
        _Transactions(),
        const FinancialCalculationService(),
        _Categories(),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PeriodPickerSheet.show(context, controller),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    for (final label in [
      'Hari ini',
      '1 Minggu',
      'Bulan ini',
      '1 Bulan',
      '3 Bulan',
      'Tahun ini',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    await tester.tap(find.text('1 Minggu'));
    await tester.pumpAndSettle();
    expect(controller.preset.value, DateRangePreset.week);
  });

  testWidgets('Bulan ini bisa dipilih kembali dari pemilih', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = Get.put(
      DashboardController(
        _Transactions(),
        const FinancialCalculationService(),
        _Categories(),
      ),
    );
    await controller.setPreset(DateRangePreset.today);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PeriodPickerSheet.show(context, controller),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bulan ini'));
    await tester.pumpAndSettle();

    expect(controller.preset.value, DateRangePreset.currentMonth);
  });
}
