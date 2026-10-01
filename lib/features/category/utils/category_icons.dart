import 'package:flutter/material.dart';

/// Memetakan `icon_key` di database ke ikon Material.
abstract final class CategoryIcons {
  static const fallback = Icons.category_rounded;

  static const _icons = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'movie': Icons.movie_rounded,
    'family_restroom': Icons.family_restroom_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'payments': Icons.payments_rounded,
    'work': Icons.work_rounded,
    'business_center': Icons.business_center_rounded,
    'trending_up': Icons.trending_up_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
  };

  static IconData of(String key) => _icons[key] ?? fallback;

  static List<String> get keys => _icons.keys.toList();
}
