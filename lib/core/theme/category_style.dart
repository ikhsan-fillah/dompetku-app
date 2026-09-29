import 'package:flutter/material.dart';

/// Menerjemahkan data kategori di database ke ikon dan warna tampilan.
/// Warna pastel lama pada data seed dipetakan ke warna cerah desain baru,
/// sehingga database yang sudah ada tidak perlu dimigrasi.
abstract final class CategoryStyle {
  static IconData icon(String key) => _icons[key] ?? Icons.category_outlined;

  static Color color(int stored) => _vibrant[stored] ?? Color(stored);

  static const Map<String, IconData> _icons = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'receipt_long': Icons.receipt_long,
    'health_and_safety': Icons.health_and_safety,
    'school': Icons.school,
    'fitness_center': Icons.fitness_center,
    'movie': Icons.movie,
    'family_restroom': Icons.family_restroom,
    'more_horiz': Icons.more_horiz,
    'payments': Icons.payments,
    'work': Icons.work,
    'business_center': Icons.business_center,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard,
  };

  static const Map<int, Color> _vibrant = {
    0xFFE57373: Color(0xFFF59E0B),
    0xFF64B5F6: Color(0xFF38BDF8),
    0xFFBA68C8: Color(0xFF8B5CF6),
    0xFFFFB74D: Color(0xFF14B8A6),
    0xFF81C784: Color(0xFFEC4899),
    0xFF4DB6AC: Color(0xFF6366F1),
    0xFFFF8A65: Color(0xFFF97316),
    0xFFA1887F: Color(0xFFD946EF),
    0xFF7986CB: Color(0xFFEAB308),
    0xFF90A4AE: Color(0xFF64748B),
  };
}
