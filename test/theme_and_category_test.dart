import 'package:dompetku_app/core/theme/app_colors.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/theme/category_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test('tema hanya light dan memakai palet Paper & Ink', () {
    final theme = AppTheme.light;
    expect(theme.brightness, Brightness.light);
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.ink);
    expect(theme.scaffoldBackgroundColor, AppColors.paper);
  });

  group('CategoryStyle', () {
    test('memetakan warna seed lama ke palet kategori desain', () {
      expect(CategoryStyle.color(0xFFE57373), AppColors.catFood);
      expect(CategoryStyle.color(0xFF64B5F6), AppColors.catTransport);
      expect(CategoryStyle.color(0xFFBA68C8), AppColors.catShopping);
    });

    test('warna kustom dipertahankan', () {
      expect(CategoryStyle.color(0xFF123456), const Color(0xFF123456));
    });

    test('ikon dikenali dan ada cadangan untuk kunci tak dikenal', () {
      expect(CategoryStyle.icon('restaurant'), LucideIcons.utensils);
      expect(CategoryStyle.icon('tidak_ada'), LucideIcons.layoutGrid);
    });
  });
}
