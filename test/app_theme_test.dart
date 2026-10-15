import 'package:dompetku_app/core/theme/app_colors.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme.light memakai palet Paper & Ink dan Material 3', () {
    final theme = AppTheme.light;

    expect(theme.brightness, Brightness.light);
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, AppColors.paper);
    expect(theme.colorScheme.primary, AppColors.ink);
    expect(theme.colorScheme.surface, AppColors.card);
    expect(theme.colorScheme.onSurface, AppColors.ink);
  });

  test('kontras teks terbaca pada tema terang', () {
    final light = AppTheme.light.colorScheme;

    expect(
      light.onSurface.computeLuminance(),
      lessThan(light.surface.computeLuminance()),
    );
  });

  testWidgets('aplikasi selalu memakai tema terang', (tester) async {
    Brightness? brightness;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (context) {
            brightness = Theme.of(context).brightness;
            return const Scaffold(body: Text('Tampilan'));
          },
        ),
      ),
    );

    expect(brightness, Brightness.light);
    expect(find.text('Tampilan'), findsOneWidget);
  });
}
