import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_skeleton.dart';
import 'package:dompetku_app/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() {
    AppToast.hide();
    Get.reset();
  });

  Future<BuildContext> host(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            captured = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );
    return captured;
  }

  group('AppToast', () {
    testWidgets('muncul di atas lalu hilang sendiri', (tester) async {
      final context = await host(tester);

      AppToast.show(
        context: context,
        title: 'Pengeluaran tersimpan',
        message: 'Kopi susu',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final toast = find.text('Pengeluaran tersimpan');
      expect(toast, findsOneWidget);
      expect(find.text('Kopi susu'), findsOneWidget);
      expect(tester.getTopLeft(toast).dy, lessThan(120));

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
    });

    testWidgets('tombol Urungkan menjalankan aksi lalu menutup', (
      tester,
    ) async {
      final context = await host(tester);
      var undone = false;

      AppToast.show(
        context: context,
        title: 'Transaksi dihapus',
        kind: ToastKind.undo,
        actionLabel: 'Urungkan',
        onAction: () => undone = true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Urungkan'));
      await tester.pumpAndSettle();

      expect(undone, isTrue);
      expect(find.text('Transaksi dihapus'), findsNothing);
    });

    testWidgets('toast baru menggantikan yang lama', (tester) async {
      final context = await host(tester);

      AppToast.show(context: context, title: 'Pertama');
      await tester.pump(const Duration(milliseconds: 300));
      AppToast.show(context: context, title: 'Kedua');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pertama'), findsNothing);
      expect(find.text('Kedua'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('skeleton diam saat HP meminta gerak dikurangi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SingleChildScrollView(child: HomeSkeleton())),
        ),
      ),
    );

    // Tanpa animasi berulang, pumpAndSettle selesai.
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
