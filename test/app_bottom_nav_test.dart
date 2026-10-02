import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(AppBottomNav nav) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: nav),
  ),
);

void main() {
  testWidgets('mengetuk tab memanggil onSelect dengan indeks yang benar', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      _host(
        AppBottomNav(
          currentIndex: 0,
          onSelect: (index) => selected = index,
          onAdd: () {},
        ),
      ),
    );

    await tester.tap(find.text('Transaksi'));
    expect(selected, 1);
    await tester.tap(find.text('Anggaran'));
    expect(selected, 2);
    await tester.tap(find.text('Profil'));
    expect(selected, 3);
    await tester.tap(find.text('Beranda'));
    expect(selected, 0);
  });

  testWidgets('tombol tambah di tengah memanggil onAdd', (tester) async {
    var added = false;
    await tester.pumpWidget(
      _host(
        AppBottomNav(
          currentIndex: 0,
          onSelect: (_) {},
          onAdd: () => added = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(added, isTrue);
  });
}
