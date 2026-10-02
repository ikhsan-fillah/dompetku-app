import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/budget_status.dart';
import 'package:dompetku_app/core/widgets/app_button.dart';
import 'package:dompetku_app/core/widgets/app_chip.dart';
import 'package:dompetku_app/core/widgets/app_progress_bar.dart';
import 'package:dompetku_app/core/widgets/app_state_view.dart';
import 'package:dompetku_app/core/widgets/budget_level_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppChip memanggil onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(AppChip(label: '1 Bulan', onTap: () => tapped = true)),
    );
    await tester.tap(find.text('1 Bulan'));
    expect(tapped, isTrue);
  });

  testWidgets('AppButton aktif memanggil onPressed', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      _host(
        AppButton(label: 'Simpan', expand: false, onPressed: () => count++),
      ),
    );
    await tester.tap(find.text('Simpan'));
    expect(count, 1);
  });

  testWidgets('AppButton tidak bereaksi saat loading', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      _host(
        AppButton(
          label: 'Simpan',
          expand: false,
          loading: true,
          onPressed: () => count++,
        ),
      ),
    );
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(count, 0);
  });

  testWidgets('AppProgressBar tampil tanpa error untuk nilai di luar batas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const SizedBox(width: 200, child: AppProgressBar(value: 1.7))),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AppProgressBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppEmptyView menampilkan judul dan pesan', (tester) async {
    await tester.pumpWidget(
      _host(const AppEmptyView(title: 'Kosong', message: 'Belum ada data')),
    );
    expect(find.text('Kosong'), findsOneWidget);
    expect(find.text('Belum ada data'), findsOneWidget);
  });

  testWidgets('AppErrorView memanggil onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _host(AppErrorView(message: 'Gagal', onRetry: () => retried = true)),
    );
    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
  });

  test('label status anggaran sesuai mockup', () {
    expect(BudgetLevel.safe.label, 'Aman');
    expect(BudgetLevel.warning.label, 'Waspada');
    expect(BudgetLevel.critical.label, 'Kritis');
    expect(BudgetLevel.exceeded.label, 'Habis');
  });
}
