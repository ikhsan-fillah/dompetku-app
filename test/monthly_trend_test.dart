import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/i18n/app_language.dart';
import 'package:dompetku_app/core/i18n/app_translations.dart';
import 'package:dompetku_app/core/services/data_refresh_service.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/trend/controllers/spending_trend_controller.dart';
import 'package:dompetku_app/features/trend/services/monthly_trend_service.dart';
import 'package:dompetku_app/features/trend/widgets/spending_trend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Transactions implements TransactionRepository {
  _Transactions(this.items);

  List<TransactionModel> items;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async =>
      List.of(items);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TransactionModel _tx(
  DateTime date,
  int amount, {
  TransactionType type = TransactionType.expense,
}) => TransactionModel(
  type: type,
  title: 'T',
  amount: amount,
  transactionDate: date,
  categoryId: 1,
  createdAt: date,
  updatedAt: date,
);

final _now = DateTime(2026, 10, 22, 14);

void main() {
  const service = MonthlyTrendService();

  group('panjang bulan mengikuti kalender', () {
    int daysOf(int year, int month) =>
        service.build(const [], DateTime(year, month), now: _now).daysInMonth;

    test('31, 30, 28, dan 29 hari', () {
      expect(daysOf(2026, 1), 31);
      expect(daysOf(2026, 4), 30);
      expect(daysOf(2025, 2), 28);
      expect(daysOf(2024, 2), 29);
      expect(daysOf(2026, 12), 31);
    });

    test('tahun abad: 2000 kabisat, 2100 bukan', () {
      expect(daysOf(2000, 2), 29);
      expect(daysOf(2100, 2), 28);
    });

    test('daily selalu sepanjang bulan', () {
      expect(
        service.build(const [], DateTime(2024, 2), now: _now).daily,
        hasLength(29),
      );
    });
  });

  group('build', () {
    test('bulan berjalan: hari berjalan sampai hari ini', () {
      final trend = service.build(
        [
          _tx(DateTime(2026, 10, 12), 220000),
          _tx(DateTime(2026, 10, 1), 100000),
        ],
        DateTime(2026, 10),
        now: _now,
      );

      expect(trend.isCurrent, isTrue);
      expect(trend.elapsedDays, 22);
      expect(trend.isInProgress, isTrue);
      expect(trend.daily[11], 220000);
      expect(trend.daily[0], 100000);
      expect(trend.total, 320000);
      expect(trend.average, closeTo(320000 / 22, 0.001));
      expect(trend.peakIndex, 11);
    });

    test('bulan lampau penuh, rata-rata dibagi seluruh hari', () {
      final trend = service.build(
        [_tx(DateTime(2025, 2, 28), 280000)],
        DateTime(2025, 2),
        now: _now,
      );

      expect(trend.isCurrent, isFalse);
      expect(trend.elapsedDays, 28);
      expect(trend.isInProgress, isFalse);
      expect(trend.average, closeTo(10000, 0.001));
    });

    test('pemasukan, bulan lain, dan hari setelah hari ini diabaikan', () {
      final trend = service.build(
        [
          _tx(DateTime(2026, 10, 5), 1000, type: TransactionType.income),
          _tx(DateTime(2026, 9, 5), 2000),
          _tx(DateTime(2026, 10, 25), 3000),
          _tx(DateTime(2026, 10, 22), 400),
        ],
        DateTime(2026, 10),
        now: _now,
      );

      expect(trend.total, 400);
      expect(trend.daily[21], 400);
    });

    test('hari terakhir bulan berjalan tidak lagi dianggap berjalan', () {
      final trend = service.build(
        const [],
        DateTime(2026, 10),
        now: DateTime(2026, 10, 31, 20),
      );

      expect(trend.elapsedDays, 31);
      expect(trend.isCurrent, isTrue);
      expect(trend.isInProgress, isFalse);
    });

    test('bulan tanpa pengeluaran tidak punya hari tertinggi', () {
      final trend = service.build(const [], DateTime(2026, 10), now: _now);

      expect(trend.peakIndex, isNull);
      expect(trend.average, 0);
    });

    test('pekan dimulai Senin', () {
      // 1 Oktober 2026 = Kamis, 5 Oktober = Senin.
      final trend = service.build(const [], DateTime(2026, 10), now: _now);

      expect(trend.weekOffset, 3);
      expect(trend.isMonday(4), isTrue);
      expect(trend.isMonday(0), isFalse);
      expect(trend.weekOf(0), 0);
      expect(trend.weekOf(3), 0);
      expect(trend.weekOf(4), 1);
      expect(trend.weekOf(11), 2);
    });
  });

  group('availableMonths', () {
    test('bulan ini selalu ada walau tanpa transaksi', () {
      expect(service.availableMonths(const [], now: _now), [
        DateTime(2026, 10),
      ]);
    });

    test('bulan bertransaksi, unik, urut, tanpa bulan depan', () {
      final months = service.availableMonths([
        _tx(DateTime(2026, 8, 3), 1),
        _tx(DateTime(2026, 8, 20), 1),
        _tx(DateTime(2025, 2, 1), 1),
        _tx(DateTime(2026, 12, 1), 1),
      ], now: _now);

      expect(months, [
        DateTime(2025, 2),
        DateTime(2026, 8),
        DateTime(2026, 10),
      ]);
    });
  });

  group('SpendingTrendController', () {
    late _Transactions repository;

    SpendingTrendController build() {
      repository = _Transactions([
        _tx(DateTime(2025, 2, 10), 50000),
        _tx(DateTime(2026, 8, 4), 70000),
        _tx(DateTime(2026, 10, 12), 220000),
        _tx(DateTime(2026, 10, 1), 100000),
      ]);
      return Get.put(SpendingTrendController(repository, clock: () => _now));
    }

    tearDown(Get.reset);

    test('mulai di bulan ini dan tidak bisa maju', () async {
      final controller = build();
      await pumpEventQueue();

      expect(controller.month.value, DateTime(2026, 10));
      expect(controller.canGoNext, isFalse);
      expect(controller.canGoPrevious, isTrue);
      expect(controller.trend.value!.total, 320000);
    });

    test('panah kiri melompati bulan tanpa transaksi', () async {
      final controller = build();
      await pumpEventQueue();

      controller.previousMonth();
      expect(controller.month.value, DateTime(2026, 8));
      expect(controller.trend.value!.daysInMonth, 31);

      controller.previousMonth();
      expect(controller.month.value, DateTime(2025, 2));
      expect(controller.trend.value!.daysInMonth, 28);
      expect(controller.canGoPrevious, isFalse);
    });

    test('panah kanan kembali sampai bulan ini lalu berhenti', () async {
      final controller = build();
      await pumpEventQueue();
      controller.previousMonth();
      controller.previousMonth();

      controller.nextMonth();
      controller.nextMonth();
      controller.nextMonth();

      expect(controller.month.value, DateTime(2026, 10));
    });

    test('mengetuk batang memilih, mengetuk lagi melepas', () async {
      final controller = build();
      await pumpEventQueue();

      controller.selectDay(11);
      expect(controller.selectedDay.value, 11);
      controller.selectDay(11);
      expect(controller.selectedDay.value, isNull);
    });

    test('hari yang belum berjalan tidak bisa dipilih', () async {
      final controller = build();
      await pumpEventQueue();

      controller.selectDay(25);

      expect(controller.selectedDay.value, isNull);
    });

    test('pindah bulan melepas pilihan hari', () async {
      final controller = build();
      await pumpEventQueue();
      controller.selectDay(3);

      controller.previousMonth();

      expect(controller.selectedDay.value, isNull);
    });

    test('data berubah memuat ulang lewat DataRefreshService', () async {
      Get.put(DataRefreshService());
      final controller = build();
      await pumpEventQueue();
      expect(controller.trend.value!.total, 320000);

      repository.items = [
        ...repository.items,
        _tx(DateTime(2026, 10, 2), 5000),
      ];
      Get.find<DataRefreshService>().bump();
      await pumpEventQueue();

      expect(controller.trend.value!.total, 325000);
    });

    test('bulan terpilih yang hilang kembali ke bulan ini', () async {
      final controller = build();
      await pumpEventQueue();
      controller.previousMonth();
      controller.previousMonth();
      expect(controller.month.value, DateTime(2025, 2));

      repository.items = [_tx(DateTime(2026, 10, 12), 1000)];
      await controller.load();

      expect(controller.month.value, DateTime(2026, 10));
    });
  });

  group('SpendingTrendCard', () {
    late _Transactions repository;

    setUp(() {
      Get.testMode = true;
      repository = _Transactions([
        _tx(DateTime(2025, 2, 10), 50000),
        _tx(DateTime(2026, 8, 4), 70000),
        _tx(DateTime(2026, 10, 12), 220000),
        _tx(DateTime(2026, 10, 1), 100000),
      ]);
      Get.put(SpendingTrendController(repository, clock: () => _now));
    });

    tearDown(Get.reset);

    Future<void> open(WidgetTester tester, {double width = 390}) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: SpendingTrendCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    int barCount() => find
        .byWidgetPredicate((w) {
          final key = w.key;
          return key is ValueKey<String> && key.value.startsWith('trend-bar-');
        })
        .evaluate()
        .length;

    testWidgets('judul, bulan, rata-rata, dan total ditampilkan', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Tren pengeluaran'), findsOneWidget);
      expect(find.text('Okt 2026'), findsOneWidget);
      expect(find.text('Rata-rata Rp 14.545 per hari'), findsOneWidget);
      expect(find.text('Total · 22 dari 31 hari'), findsOneWidget);
      expect(find.text('Rp 320.000'), findsOneWidget);
      expect(find.text('Ketuk batang'), findsOneWidget);
    });

    testWidgets('jumlah batang sama dengan jumlah hari bulan itu', (
      tester,
    ) async {
      await open(tester);
      expect(barCount(), 31);

      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();
      expect(find.text('Agu 2026'), findsOneWidget);
      expect(barCount(), 31);
      expect(find.text('Total · 31 hari'), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();
      expect(find.text('Feb 2025'), findsOneWidget);
      expect(barCount(), 28);
      expect(find.text('Total · 28 hari'), findsOneWidget);
    });

    testWidgets('panah kanan mati di bulan ini', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(LucideIcons.chevronRight));
      await tester.pumpAndSettle();

      expect(find.text('Okt 2026'), findsOneWidget);
    });

    testWidgets('panah kiri mati di bulan paling awal', (tester) async {
      await open(tester);
      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();

      expect(find.text('Feb 2025'), findsOneWidget);
    });

    testWidgets('mengetuk batang menampilkan tanggal dan nominal', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('trend-bar-11')));
      await tester.pumpAndSettle();

      expect(find.text('12 Okt · Rp 220.000'), findsOneWidget);
      expect(find.text('Ketuk batang'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('trend-bar-11')));
      await tester.pumpAndSettle();
      expect(find.text('12 Okt · Rp 220.000'), findsNothing);
    });

    testWidgets('gelembung berukuran seperti teksnya, bukan seluruh grafik', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('trend-bar-11')));
      await tester.pumpAndSettle();

      final text = find.text('12 Okt · Rp 220.000');
      final bubble = find
          .ancestor(of: text, matching: find.byType(Container))
          .first;
      final size = tester.getSize(bubble);
      expect(size.height, lessThan(40));
      expect(size.width, lessThan(220));
      expect(size.width, greaterThan(tester.getSize(text).width));
    });

    testWidgets('batang hari yang belum berjalan tidak bisa dipilih', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('trend-bar-27')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Okt ·'), findsNothing);
    });

    testWidgets('gelembung tetap di dalam kartu untuk batang di tepi', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('trend-bar-0')));
      await tester.pumpAndSettle();

      expect(find.text('1 Okt · Rp 100.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa overflow di layar sempit', (tester) async {
      await open(tester, width: 320);

      expect(tester.takeException(), isNull);
    });

    testWidgets('label bulan mengikuti bahasa Inggris', (tester) async {
      Get.addTranslations(AppTranslations().keys);
      Get.locale = AppLanguage.localeFor(AppLanguage.english);
      addTearDown(() {
        Get.locale = null;
        Get.clearTranslations();
      });

      await open(tester);

      expect(find.text('Oct 2026'), findsOneWidget);
    });
  });
}
