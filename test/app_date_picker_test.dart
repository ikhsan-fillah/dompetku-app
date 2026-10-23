import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Finder _day(int year, int month, int day) =>
    find.byKey(ValueKey('date-$year-$month-$day'));

void main() {
  tearDown(Get.reset);

  Future<void> host(
    WidgetTester tester,
    Future<void> Function(BuildContext context) onOpen,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => onOpen(context),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  group('A · satu tanggal', () {
    Future<DateTime?> pick(
      WidgetTester tester,
      Future<void> Function() steps,
    ) async {
      DateTime? result;
      await host(tester, (context) async {
        result = await showAppDatePicker(
          context,
          initialDate: DateTime(2026, 3, 10),
          firstDate: DateTime(2025, 1, 1),
          lastDate: DateTime(2026, 3, 20),
        );
      });
      await steps();
      return result;
    }

    testWidgets('ketuk tanggal lalu Pilih mengembalikan tanggal itu', (
      tester,
    ) async {
      final result = await pick(tester, () async {
        expect(find.text('Pilih tanggal'), findsOneWidget);
        expect(find.text('Maret 2026'), findsOneWidget);
        await tester.tap(_day(2026, 3, 5));
        await tester.pumpAndSettle();
        expect(find.text('5 Mar 2026'), findsOneWidget);
        await tester.tap(find.text('Pilih'));
        await tester.pumpAndSettle();
      });

      expect(result, DateTime(2026, 3, 5));
    });

    testWidgets('tanggal setelah batas tidak bisa dipilih', (tester) async {
      final result = await pick(tester, () async {
        await tester.tap(_day(2026, 3, 25));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pilih'));
        await tester.pumpAndSettle();
      });

      expect(result, DateTime(2026, 3, 10));
    });

    testWidgets('Batal mengembalikan null', (tester) async {
      final result = await pick(tester, () async {
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
      });

      expect(result, isNull);
    });

    testWidgets('C · ketuk judul bulan untuk lompat bulan', (tester) async {
      final result = await pick(tester, () async {
        await tester.tap(find.text('Maret 2026'));
        await tester.pumpAndSettle();
        expect(find.text('2026'), findsOneWidget);

        // April 2026 di luar batas, jadi tidak bisa dipilih.
        await tester.tap(find.byKey(const ValueKey('month-2026-4')));
        await tester.pumpAndSettle();
        expect(find.text('2026'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('month-2026-1')));
        await tester.pumpAndSettle();
        expect(find.text('Januari 2026'), findsOneWidget);
        await tester.tap(_day(2026, 1, 15));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pilih'));
        await tester.pumpAndSettle();
      });

      expect(result, DateTime(2026, 1, 15));
    });

    testWidgets('panah bulan pindah bulan dan berhenti di batas', (
      tester,
    ) async {
      await pick(tester, () async {
        await tester.tap(find.bySemanticsLabel('Bulan berikutnya'));
        await tester.pumpAndSettle();
        expect(find.text('Maret 2026'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
        await tester.pumpAndSettle();
        expect(find.text('Februari 2026'), findsOneWidget);
      });
    });
  });

  group('B · rentang', () {
    Future<DateTimeRange?> pick(
      WidgetTester tester,
      Future<void> Function() steps, {
      bool editEnd = false,
    }) async {
      DateTimeRange? result;
      await host(tester, (context) async {
        result = await showAppDateRangePicker(
          context,
          initialRange: DateTimeRange(
            start: DateTime(2026, 3, 6),
            end: DateTime(2026, 3, 17),
          ),
          firstDate: DateTime(2025, 1, 1),
          lastDate: DateTime(2026, 3, 20),
          editEnd: editEnd,
        );
      });
      await steps();
      return result;
    }

    testWidgets('isi Dari lalu Sampai, jumlah hari ikut berubah', (
      tester,
    ) async {
      final result = await pick(tester, () async {
        expect(find.text('Periode kustom'), findsOneWidget);
        expect(find.text('12 hari dipilih'), findsOneWidget);

        await tester.tap(_day(2026, 3, 2));
        await tester.pumpAndSettle();
        await tester.tap(_day(2026, 3, 4));
        await tester.pumpAndSettle();
        expect(find.text('3 hari dipilih'), findsOneWidget);

        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();
      });

      expect(result!.start, DateTime(2026, 3, 2));
      expect(result.end, DateTime(2026, 3, 4));
    });

    testWidgets('di Sampai, tanggal sebelum awal menjadi awal baru', (
      tester,
    ) async {
      final result = await pick(tester, editEnd: true, () async {
        await tester.tap(_day(2026, 3, 1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();
      });

      expect(result!.start, DateTime(2026, 3, 1));
      expect(result.end, DateTime(2026, 3, 17));
    });

    testWidgets('awal setelah akhir menggeser akhir ikut maju', (tester) async {
      final result = await pick(tester, () async {
        await tester.tap(_day(2026, 3, 19));
        await tester.pumpAndSettle();
        expect(find.text('1 hari dipilih'), findsOneWidget);
        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();
      });

      expect(result!.start, DateTime(2026, 3, 19));
      expect(result.end, DateTime(2026, 3, 19));
    });
  });
}
