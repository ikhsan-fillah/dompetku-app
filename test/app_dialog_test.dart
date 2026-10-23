import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_button.dart';
import 'package:dompetku_app/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  Future<void> open(
    WidgetTester tester,
    void Function(bool) onResult, {
    bool danger = true,
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => onResult(
                  await showAppConfirm(
                    context,
                    title: 'Hapus transaksi?',
                    message: 'Transaksi ini akan dihapus permanen.',
                    confirmLabel: 'Hapus',
                    danger: danger,
                  ),
                ),
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

  testWidgets('dua tombol memakai AppButton: Batal outline, Hapus danger', (
    tester,
  ) async {
    await open(tester, (_) {});

    final buttons = tester
        .widgetList<AppButton>(find.byType(AppButton))
        .toList();
    expect(buttons.map((b) => b.label), ['Batal', 'Hapus']);
    expect(buttons[0].kind, AppButtonKind.outline);
    expect(buttons[1].kind, AppButtonKind.danger);
    expect(find.byType(TextButton), findsOneWidget); // hanya pemicu uji
  });

  testWidgets('aksi non-danger memakai tombol utama', (tester) async {
    await open(tester, (_) {}, danger: false);

    final confirm = tester.widgetList<AppButton>(find.byType(AppButton)).last;
    expect(confirm.kind, AppButtonKind.primary);
  });

  testWidgets('menekan aksi mengembalikan true', (tester) async {
    bool? result;
    await open(tester, (value) => result = value);

    await tester.tap(find.widgetWithText(AppButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('menekan Batal mengembalikan false', (tester) async {
    bool? result;
    await open(tester, (value) => result = value);

    await tester.tap(find.widgetWithText(AppButton, 'Batal'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('kedua tombol sama lebar dan sejajar', (tester) async {
    await open(tester, (_) {});

    final cancel = tester.getRect(find.widgetWithText(AppButton, 'Batal'));
    final confirm = tester.getRect(find.widgetWithText(AppButton, 'Hapus'));
    expect(cancel.width, confirm.width);
    expect(cancel.top, confirm.top);
    expect(cancel.height, confirm.height);
  });
}
