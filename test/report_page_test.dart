import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/i18n/app_language.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_card.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/report/controllers/report_controller.dart';
import 'package:dompetku_app/features/report/views/report_page.dart';
import 'package:dompetku_app/features/report/widgets/report_visuals.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/trend/widgets/report_trend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Transactions implements TransactionRepository {
  _Transactions(this.items);

  final List<TransactionModel> items;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async =>
      List.of(items);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async => [
    CategoryModel(
      id: 1,
      name: 'Makanan',
      type: TransactionType.expense,
      iconKey: 'restaurant',
      colorValue: 0xFFE57373,
      isDefault: false,
      isFavorite: false,
      sortOrder: 1,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TransactionModel _tx(TransactionType type, int amount, DateTime date) =>
    TransactionModel(
      id: amount,
      type: type,
      title: 'Kopi',
      amount: amount,
      transactionDate: date,
      categoryId: 1,
      createdAt: date,
      updatedAt: date,
    );

void main() {
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);

  setUp(() {
    Get.testMode = true;
    Get.put(
      ReportController(
        _Transactions([
          _tx(TransactionType.expense, 75000, firstOfMonth),
          _tx(TransactionType.income, 500000, firstOfMonth),
        ]),
        _Categories(),
        const FinancialCalculationService(),
      ),
    );
  });

  tearDown(Get.reset);

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const ReportPage()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hanya pilihan bulan, tanpa chip rentang tanggal', (
    tester,
  ) async {
    await open(tester);

    expect(find.text(AppLanguage.monthLong(now.month)), findsOneWidget);
    expect(find.text('${now.year}'), findsOneWidget);
    expect(find.text('Kustom'), findsNothing);
    expect(find.text('Hari ini'), findsNothing);
    expect(find.text('1 Minggu'), findsNothing);
  });

  testWidgets('menampilkan visual dan judul statistik pengeluaran', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(SpendingRing), findsOneWidget);
    expect(find.byType(IncomeExpenseOverview), findsOneWidget);
    // Pemilih bulan ada di kartu yang sama dengan cincin pengeluaran.
    final ringCard = find.ancestor(
      of: find.byType(SpendingRing),
      matching: find.byType(AppCard),
    );
    expect(
      find.descendant(of: ringCard, matching: find.byType(MonthSwitcher)),
      findsOneWidget,
    );
    expect(find.text('Tren pengeluaran'), findsOneWidget);
    expect(find.text('Pengeluaran harian'), findsNothing);
    expect(find.text('Statistik pengeluaran'), findsOneWidget);
    expect(find.text('Statistik belanja'), findsNothing);
    expect(find.text('Rincian pengeluaran'), findsOneWidget);
    expect(find.text('Rp75.000'), findsWidgets);
  });

  testWidgets('kartu tren pemasukan tampil dan batangnya bisa diketuk', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Tren pemasukan'), findsOneWidget);
    expect(find.text('1 pemasukan'), findsOneWidget);
    // Kartu pengeluaran dan pemasukan sama-sama punya petunjuk.
    expect(find.text('Ketuk batang'), findsNWidgets(2));

    final card = find.ancestor(
      of: find.text('Tren pemasukan'),
      matching: find.byType(ReportTrendCard),
    );
    final bar = find.descendant(
      of: card,
      matching: find.byKey(const ValueKey('trend-bar-0')),
    );
    await tester.ensureVisible(bar);
    await tester.tap(bar);
    await tester.pumpAndSettle();

    expect(find.textContaining('500.000'), findsWidgets);
    expect(find.text('Ketuk batang'), findsOneWidget);
  });

  testWidgets('ketuk cincin menampilkan kategori di tengah', (tester) async {
    await open(tester);
    final ring = find.byType(SpendingRing);
    expect(find.text('Total pengeluaran'), findsOneWidget);

    // Satu kategori mengisi seluruh cincin; ketuk sisi atasnya.
    final rect = tester.getRect(ring);
    final side = rect.height < rect.width ? rect.height : rect.width;
    await tester.tapAt(Offset(rect.center.dx, rect.center.dy - side * 0.44));
    await tester.pumpAndSettle();

    expect(find.text('Makanan'), findsWidgets);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Total pengeluaran'), findsNothing);

    await tester.tapAt(Offset(rect.center.dx, rect.center.dy - side * 0.44));
    await tester.pumpAndSettle();
    expect(find.text('Total pengeluaran'), findsOneWidget);
  });

  testWidgets('bulan berjalan tidak bisa maju, bulan lalu bisa dibuka', (
    tester,
  ) async {
    await open(tester);

    final next = find.bySemanticsLabel('Bulan berikutnya');
    expect(next, findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(Get.find<ReportController>().month.value, firstOfMonth);

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    final previous = DateTime(now.year, now.month - 1);
    expect(Get.find<ReportController>().month.value, previous);
    expect(find.text(AppLanguage.monthLong(previous.month)), findsOneWidget);
    // Bulan kosong tetap menampilkan semua kartu, bukan hanya pesan.
    expect(find.text('Belum ada transaksi pada bulan ini'), findsOneWidget);
    expect(find.byType(SpendingRing), findsOneWidget);
    expect(find.byType(IncomeExpenseOverview), findsOneWidget);
    expect(find.text('Tren pengeluaran'), findsOneWidget);
    expect(find.text('Pengeluaran harian'), findsNothing);
    expect(find.text('Statistik pengeluaran'), findsOneWidget);
    expect(find.text('Rincian pengeluaran'), findsOneWidget);
    expect(find.text('Belum ada pengeluaran pada bulan ini.'), findsOneWidget);
    expect(find.text('Muat ulang'), findsNothing);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const ReportPage()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SpendingRing), findsOneWidget);
  });
}
