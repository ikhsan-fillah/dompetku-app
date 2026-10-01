import 'package:dompetku_app/features/category/utils/category_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CategoryIcons memetakan kunci ikon yang dikenal dan fallback untuk kunci tak dikenal',
    () {
      expect(CategoryIcons.keys.length, 15);
      expect(CategoryIcons.of('restaurant'), Icons.restaurant_rounded);
      expect(CategoryIcons.of('payments'), Icons.payments_rounded);
      expect(CategoryIcons.of('card_giftcard'), Icons.card_giftcard_rounded);
      expect(CategoryIcons.of('not_found'), CategoryIcons.fallback);
    },
  );
}
