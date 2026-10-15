import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Memetakan `icon_key` di database ke ikon Lucide (monoline).
abstract final class CategoryIcons {
  static const fallback = LucideIcons.layoutGrid;

  static const _icons = <String, IconData>{
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

  static IconData of(String key) => _icons[key] ?? fallback;

  static List<String> get keys => _icons.keys.toList();
}
