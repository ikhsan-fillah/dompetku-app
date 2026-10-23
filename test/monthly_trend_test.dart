import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/trend/services/monthly_trend_service.dart';
import 'package:dompetku_app/features/trend/models/monthly_trend.dart';
import 'package:dompetku_app/features/trend/widgets/report_trend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

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

  group('candidateMonths dan monthRange', () {
    test('tanpa transaksi hanya bulan ini', () {
      expect(service.candidateMonths(null, now: _now), [DateTime(2026, 10)]);
    });

    test('dari bulan transaksi pertama sampai bulan ini, urut', () {
      expect(service.candidateMonths(DateTime(2026, 8, 20), now: _now), [
        DateTime(2026, 8),
        DateTime(2026, 9),
        DateTime(2026, 10),
      ]);
    });

    test('melewati pergantian tahun', () {
      final months = service.candidateMonths(DateTime(2025, 11, 3), now: _now);

      expect(months.first, DateTime(2025, 11));
      expect(months[2], DateTime(2026, 1));
      expect(months.last, DateTime(2026, 10));
      expect(months, hasLength(12));
    });

    test('tanggal pertama di masa depan diabaikan', () {
      expect(service.candidateMonths(DateTime(2027, 1, 1), now: _now), [
        DateTime(2026, 10),
      ]);
    });

    test('monthRange mencakup 1 sampai hari terakhir, termasuk kabisat', () {
      final feb = MonthlyTrendService.monthRange(DateTime(2024, 2, 17));
      expect(feb.start, DateTime(2024, 2, 1));
      expect(feb.end, DateTime(2024, 2, 29));
      expect(
        MonthlyTrendService.monthRange(DateTime(2026, 12)).end,
        DateTime(2026, 12, 31),
      );
    });
  });

  group('ReportTrendCard', () {
    final trend = service.build(
      [_tx(DateTime(2026, 10, 12), 220000), _tx(DateTime(2026, 10, 1), 100000)],
      DateTime(2026, 10),
      now: _now,
    );

    Future<void> open(
      WidgetTester tester,
      MonthlyTrend value, {
      double width = 390,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(child: ReportTrendCard(trend: value)),
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

    testWidgets('judul, rata-rata, dan total, tanpa panah bulan', (
      tester,
    ) async {
      await open(tester, trend);

      expect(find.text('Tren pengeluaran'), findsOneWidget);
      expect(find.text('Rata-rata Rp 14.545 per hari'), findsOneWidget);
      expect(find.text('Total · 22 dari 31 hari'), findsOneWidget);
      expect(find.text('Rp 320.000'), findsOneWidget);
      expect(find.text('Ketuk batang'), findsOneWidget);
      expect(find.bySemanticsLabel('Bulan sebelumnya'), findsNothing);
    });

    testWidgets('jumlah batang sama dengan jumlah hari bulan itu', (
      tester,
    ) async {
      await open(tester, trend);
      expect(barCount(), 31);

      await open(tester, service.build(const [], DateTime(2025, 2), now: _now));
      expect(barCount(), 28);
      expect(find.text('Total · 28 hari'), findsOneWidget);
    });

    testWidgets('mengetuk batang menampilkan tanggal dan nominal', (
      tester,
    ) async {
      await open(tester, trend);

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
      await open(tester, trend);

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
      await open(tester, trend);

      await tester.tap(find.byKey(const ValueKey('trend-bar-27')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Okt ·'), findsNothing);
    });

    testWidgets('gelembung tetap di dalam kartu untuk batang di tepi', (
      tester,
    ) async {
      await open(tester, trend);

      await tester.tap(find.byKey(const ValueKey('trend-bar-0')));
      await tester.pumpAndSettle();

      expect(find.text('1 Okt · Rp 100.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa overflow di layar sempit', (tester) async {
      await open(tester, trend, width: 320);

      expect(tester.takeException(), isNull);
    });

    testWidgets('pemasukan memakai judul dan keterangan jumlah', (
      tester,
    ) async {
      await open(
        tester,
        service.build(
          [_tx(DateTime(2026, 10, 1), 5000000, type: TransactionType.income)],
          DateTime(2026, 10),
          now: _now,
          type: TransactionType.income,
        ),
      );

      expect(find.text('Tren pemasukan'), findsOneWidget);
      expect(find.text('1 pemasukan'), findsOneWidget);
      expect(find.textContaining('Rata-rata'), findsNothing);
    });
  });

  group('tren pemasukan', () {
    test('type income menghitung pemasukan saja dan jumlah transaksinya', () {
      final trend = service.build(
        [
          _tx(DateTime(2026, 10, 1), 5000000, type: TransactionType.income),
          _tx(DateTime(2026, 10, 1), 250000, type: TransactionType.income),
          _tx(DateTime(2026, 10, 12), 220000),
          _tx(DateTime(2026, 10, 25), 999, type: TransactionType.income),
        ],
        DateTime(2026, 10),
        now: _now,
        type: TransactionType.income,
      );

      expect(trend.type, TransactionType.income);
      expect(trend.daily[0], 5250000);
      expect(trend.daily[11], 0);
      expect(trend.total, 5250000);
      // Yang bertanggal setelah hari ini tidak dihitung.
      expect(trend.transactionCount, 2);
    });

    test('bawaan tetap pengeluaran', () {
      final trend = service.build(
        [_tx(DateTime(2026, 10, 1), 100, type: TransactionType.income)],
        DateTime(2026, 10),
        now: _now,
      );

      expect(trend.type, TransactionType.expense);
      expect(trend.total, 0);
      expect(trend.transactionCount, 0);
    });
  });
}
