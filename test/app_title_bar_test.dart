import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('judul panjang tetap satu baris dan dipotong elipsis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppTitleBar(title: 'Transportation and Commuting Costs'),
        ),
      ),
    );

    final text = tester.widget<Text>(
      find.text('Transportation and Commuting Costs'),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
    final height = tester
        .getSize(find.text('Transportation and Commuting Costs'))
        .height;
    // Satu baris display 26: jauh di bawah tinggi dua baris.
    expect(height, lessThan(50));
  });
}
