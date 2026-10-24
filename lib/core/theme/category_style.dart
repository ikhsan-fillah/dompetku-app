import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_colors.dart';
import 'duotone_icon.dart';

/// Menerjemahkan data kategori di database ke ikon dan warna tampilan.
/// Warna dan kunci ikon yang tersimpan di database tetap dipertahankan; warna
/// seed lama dipetakan ke palet kategori README bagian 5.
abstract final class CategoryStyle {
  static IconData icon(String key) => _icons[key] ?? LucideIcons.layoutGrid;

  static Color color(int stored) => _palette[stored] ?? Color(stored);

  /// Ikon Phosphor duotone untuk kotak kategori.
  static DuotoneIcon duotone(String key) =>
      _duotone[key] ?? DuotoneIcon.squaresFour;

  static const Map<String, DuotoneIcon> _duotone = {
    'restaurant': DuotoneIcon.forkKnife,
    'directions_car': DuotoneIcon.bus,
    'shopping_bag': DuotoneIcon.shoppingBag,
    'receipt_long': DuotoneIcon.receipt,
    'health_and_safety': DuotoneIcon.heart,
    'school': DuotoneIcon.graduationCap,
    'fitness_center': DuotoneIcon.barbell,
    'movie': DuotoneIcon.filmSlate,
    'family_restroom': DuotoneIcon.usersThree,
    'more_horiz': DuotoneIcon.dotsThree,
    'payments': DuotoneIcon.wallet,
    'work': DuotoneIcon.briefcase,
    'business_center': DuotoneIcon.briefcase,
    'trending_up': DuotoneIcon.trendUp,
    'card_giftcard': DuotoneIcon.gift,
  };

  static const Map<String, IconData> _icons = {
    'restaurant': LucideIcons.utensils,
    'directions_car': LucideIcons.bus,
    'shopping_bag': LucideIcons.shoppingBag,
    'receipt_long': LucideIcons.receiptText,
    'health_and_safety': LucideIcons.heart,
    'school': LucideIcons.bookOpen,
    'fitness_center': LucideIcons.dumbbell,
    'movie': LucideIcons.star,
    'family_restroom': LucideIcons.users,
    'more_horiz': LucideIcons.ellipsis,
    'payments': LucideIcons.wallet,
    'work': LucideIcons.briefcase,
    'business_center': LucideIcons.briefcase,
    'trending_up': LucideIcons.trendingUp,
    'card_giftcard': LucideIcons.gift,
  };

  static const Map<int, Color> _palette = {
    0xFFE57373: AppColors.catFood,
    0xFF64B5F6: AppColors.catTransport,
    0xFFBA68C8: AppColors.catShopping,
    0xFFFFB74D: AppColors.catBills,
    0xFF81C784: AppColors.catHealth,
    0xFF4DB6AC: AppColors.catEducation,
    0xFFFF8A65: AppColors.catEntertainment,
    0xFFA1887F: AppColors.catEntertainment,
    0xFF7986CB: AppColors.catHealth,
    0xFF90A4AE: AppColors.catOther,
    0xFF43A047: AppColors.incomeSalary,
    0xFF00897B: AppColors.incomeFreelance,
    0xFF1E88E5: AppColors.incomeBusiness,
    0xFF7CB342: AppColors.incomeInvestment,
    0xFFD81B60: AppColors.incomeGift,
  };
}
