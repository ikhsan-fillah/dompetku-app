import 'package:dompetku_app/features/category/utils/category_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  test(
    'CategoryIcons memetakan kunci ikon yang dikenal dan fallback untuk kunci tak dikenal',
    () {
      expect(CategoryIcons.keys.length, 15);
      expect(CategoryIcons.of('restaurant'), LucideIcons.utensils);
      expect(CategoryIcons.of('payments'), LucideIcons.wallet);
      expect(CategoryIcons.of('card_giftcard'), LucideIcons.gift);
      expect(CategoryIcons.of('not_found'), CategoryIcons.fallback);
    },
  );
}
