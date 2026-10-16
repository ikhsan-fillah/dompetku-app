import 'package:dompetku_app/core/theme/app_colors.dart';
import 'package:dompetku_app/features/recap/widgets/story_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StoryFrame _frame() => StoryFrame(
      footer: 'Tally · test',
      cards: [
        for (var i = 0; i < 3; i++)
          StoryCard(
            background: AppColors.ink,
            foreground: AppColors.paper,
            child: Text('card ${i + 1}'),
          ),
      ],
    );

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: _frame()));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('menampilkan kartu pertama dan penghitung', (tester) async {
    await _pump(tester);

    expect(find.text('card 1'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('auto-advance setelah 6 detik', (tester) async {
    await _pump(tester);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('card 2'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('tidak auto-advance sebelum 6 detik', (tester) async {
    await _pump(tester);

    await tester.pump(const Duration(seconds: 5));

    expect(find.text('card 1'), findsOneWidget);
  });

  testWidgets('berhenti di kartu terakhir', (tester) async {
    await _pump(tester);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('card 3'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('tap kanan maju, tap kiri mundur', (tester) async {
    await _pump(tester);

    await tester.tapAt(const Offset(700, 800));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('card 2'), findsOneWidget);

    await tester.tapAt(const Offset(20, 800));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('card 1'), findsOneWidget);
  });

  testWidgets('tap kiri di kartu pertama tidak mundur ke luar', (tester) async {
    await _pump(tester);

    await tester.tapAt(const Offset(20, 800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('card 1'), findsOneWidget);
  });
}
