import 'package:dompetku_app/core/utils/budget_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetStatus.levelFor', () {
    test('di bawah 75 persen dianggap aman', () {
      expect(BudgetStatus.levelFor(0), BudgetLevel.safe);
      expect(BudgetStatus.levelFor(74.9), BudgetLevel.safe);
    });

    test('75 sampai kurang dari 90 persen waspada', () {
      expect(BudgetStatus.levelFor(75), BudgetLevel.warning);
      expect(BudgetStatus.levelFor(89.9), BudgetLevel.warning);
    });

    test('90 sampai kurang dari 100 persen kritis', () {
      expect(BudgetStatus.levelFor(90), BudgetLevel.critical);
      expect(BudgetStatus.levelFor(99.9), BudgetLevel.critical);
    });

    test('100 persen atau lebih habis', () {
      expect(BudgetStatus.levelFor(100), BudgetLevel.exceeded);
      expect(BudgetStatus.levelFor(140), BudgetLevel.exceeded);
    });
  });

  group('BudgetStatus.percentUsed', () {
    test('menghitung persentase terpakai', () {
      expect(BudgetStatus.percentUsed(used: 3650000, limit: 5000000), 73);
    });

    test('batas nol atau negatif menghasilkan nol', () {
      expect(BudgetStatus.percentUsed(used: 100, limit: 0), 0);
      expect(BudgetStatus.percentUsed(used: 100, limit: -5), 0);
    });
  });
}
