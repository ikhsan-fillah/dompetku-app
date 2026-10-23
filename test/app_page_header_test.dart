import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('jarak header ke isi sama dengan app bar Beranda (10 px)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              AppPageHeader(
                title: 'Anggaran',
                actions: [SizedBox(width: 38, height: 38)],
              ),
              SizedBox(key: ValueKey('body'), height: 20),
            ],
          ),
        ),
      ),
    );

    final row = find
        .descendant(of: find.byType(AppPageHeader), matching: find.byType(Row))
        .first;
    final gap =
        tester.getTopLeft(find.byKey(const ValueKey('body'))).dy -
        tester.getBottomLeft(row).dy;

    expect(AppPageHeader.bottomGap, 10);
    expect(gap, AppPageHeader.bottomGap);
  });
}
