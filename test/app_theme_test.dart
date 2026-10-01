import 'package:dompetku_app/core/theme/app_colors.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme.light tetap memakai warna terang aplikasi', () {
    final theme = AppTheme.light;

    expect(theme.brightness, Brightness.light);
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.teal);
    expect(theme.colorScheme.surface, AppColors.surface);
    expect(theme.colorScheme.onSurface, AppColors.ink);
  });

  test('AppTheme.dark memakai kecerahan gelap dan Material 3', () {
    final theme = AppTheme.dark;

    expect(theme.brightness, Brightness.dark);
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.tealLight);
  });

  test('AppTheme.dark berbeda dari light pada scaffold dan permukaan', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(dark.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
    expect(dark.colorScheme.surface, isNot(light.colorScheme.surface));
  });

  test('kontras teks terbaca pada tema terang dan gelap', () {
    final light = AppTheme.light.colorScheme;
    final dark = AppTheme.dark.colorScheme;

    expect(
      light.onSurface.computeLuminance(),
      lessThan(light.surface.computeLuminance()),
    );
    expect(
      dark.onSurface.computeLuminance(),
      greaterThan(dark.surface.computeLuminance()),
    );
  });

  testWidgets('themeMode gelap menerapkan AppTheme.dark', (tester) async {
    Brightness? brightness;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            brightness = Theme.of(context).brightness;
            return const Scaffold(body: Text('Tampilan'));
          },
        ),
      ),
    );

    expect(brightness, Brightness.dark);
    expect(find.text('Tampilan'), findsOneWidget);
  });

  testWidgets('themeMode terang menerapkan AppTheme.light', (tester) async {
    Brightness? brightness;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
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
  });
}
