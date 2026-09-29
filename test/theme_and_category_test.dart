import 'package:dompetku_app/core/theme/app_colors.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/theme/category_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tema hanya light dan memakai palet DompetKu', () {
    final theme = AppTheme.light;
    expect(theme.brightness, Brightness.light);
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.teal);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  group('CategoryStyle', () {
    test('memetakan warna pastel lama ke warna cerah', () {
      expect(CategoryStyle.color(0xFFE57373), AppColors.amber);
      expect(CategoryStyle.color(0xFF64B5F6), AppColors.sky);
      expect(CategoryStyle.color(0xFFBA68C8), AppColors.violet);
    });

    test('warna kustom dipertahankan', () {
      expect(CategoryStyle.color(0xFF123456), const Color(0xFF123456));
    });

    test('ikon dikenali dan ada cadangan untuk kunci tak dikenal', () {
      expect(CategoryStyle.icon('restaurant'), Icons.restaurant);
      expect(CategoryStyle.icon('tidak_ada'), Icons.category_outlined);
    });
  });
}
