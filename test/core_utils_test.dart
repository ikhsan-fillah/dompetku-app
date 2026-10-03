import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/core/utils/formatter.dart';
import 'package:dompetku_app/core/utils/validator.dart';
import 'package:dompetku_app/core/utils/biometric_lockout.dart';
import 'package:dompetku_app/core/constant/app_constant.dart';
import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateRange', () {
    final now = DateTime(2026, 9, 28, 18, 30);

    test('creates one calendar month through today', () {
      final range = DateRange.fromPreset(DateRangePreset.month, now: now);

      expect(range.start, DateTime(2026, 8, 28));
      expect(range.end, DateTime(2026, 9, 28));
      expect(range.dayCount, 32);
    });

    test('supports calendar month and year clamping', () {
      final range = DateRange.fromPreset(
        DateRangePreset.month,
        now: DateTime(2024, 2, 29),
      );

      expect(range.start, DateTime(2024, 1, 29));
      expect(
        DateRange.fromPreset(
          DateRangePreset.month,
          now: DateTime(2026, 3, 31),
        ).start,
        DateTime(2026, 2, 28),
      );
      expect(
        DateRange.fromPreset(
          DateRangePreset.year,
          now: DateTime(2025, 2, 28),
        ).start,
        DateTime(2024, 2, 28),
      );
    });

    test(
      'supports current month, year to date, and all time through today',
      () {
        final today = DateTime(2026, 10, 3, 18, 30);
        final currentMonth = DateRange.fromPreset(
          DateRangePreset.currentMonth,
          now: today,
        );
        expect(currentMonth.start, DateTime(2026, 10, 1));
        expect(currentMonth.end, DateTime(2026, 10, 3));
        expect(
          DateRange.fromPreset(DateRangePreset.yearToDate, now: today).start,
          DateTime(2026, 1, 1),
        );
        expect(
          DateRange.fromPreset(DateRangePreset.allTime, now: today).end,
          DateTime(2026, 10, 3),
        );
      },
    );

    test('history ranges reject a future end date', () {
      expect(
        () => DateRange.history(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 4),
          now: DateTime(2026, 10, 3),
        ),
        throwsArgumentError,
      );
      expect(
        () => DateRange.history(
          start: DateTime(2026, 10, 4),
          end: DateTime(2026, 10, 3),
          now: DateTime(2026, 10, 3),
        ),
        throwsArgumentError,
      );
    });

    test('calculates every calendar month length', () {
      expect(DateRange.daysInMonth(DateTime(2026, 4)), 30);
      expect(DateRange.daysInMonth(DateTime(2024, 2)), 29);
      expect(DateRange.daysInMonth(DateTime(2026, 2)), 28);
    });

    test('rejects a start date after the end date', () {
      expect(
        () => DateRange(start: DateTime(2026, 9, 2), end: DateTime(2026, 9, 1)),
        throwsArgumentError,
      );
    });
  });

  group('IDR formatter', () {
    test('formats and parses grouped amounts', () {
      expect(formatIdr(1250000), 'Rp 1.250.000');
      expect(parseIdr('Rp 1.250.000'), 1250000);
    });

    test('returns null for an empty amount', () {
      expect(parseIdr(''), isNull);
    });
  });

  group('Validators', () {
    test('validates required text and positive amounts', () {
      expect(requiredText(''), isNotNull);
      expect(requiredText('Food'), isNull);
      expect(positiveAmount(0), isNotNull);
      expect(positiveAmount(1000), isNull);
    });
  });

  group('Biometric lockout', () {
    test('locks only on the fifth failed attempt', () {
      final now = DateTime(2026, 9, 28, 10);
      expect(BiometricLockout.lockedUntil(failureCount: 4, now: now), isNull);
      final until = BiometricLockout.lockedUntil(
        failureCount: AppConstants.maxBiometricFailures,
        now: now,
      );
      expect(until, DateTime(2026, 9, 28, 10, 5));
      expect(BiometricLockout.isLockedOut(until, now: now), isTrue);
      expect(BiometricLockout.isLockedOut(until, now: until!), isFalse);
    });
  });

  group('FinancialCalculationService', () {
    final range = DateRange(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 30),
    );
    final transactions = [
      TransactionModel(
        type: TransactionType.income,
        title: 'Salary',
        amount: 5000000,
        transactionDate: DateTime(2026, 9, 1),
        categoryId: 1,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      ),
      TransactionModel(
        type: TransactionType.expense,
        title: 'Food',
        amount: 150000,
        transactionDate: DateTime(2026, 9, 2),
        categoryId: 2,
        createdAt: DateTime(2026, 9, 2),
        updatedAt: DateTime(2026, 9, 2),
      ),
      TransactionModel(
        type: TransactionType.expense,
        title: 'Fuel',
        amount: 50000,
        transactionDate: DateTime(2026, 9, 2),
        categoryId: 3,
        createdAt: DateTime(2026, 9, 2),
        updatedAt: DateTime(2026, 9, 2),
      ),
      TransactionModel(
        type: TransactionType.expense,
        title: 'Old',
        amount: 999,
        transactionDate: DateTime(2026, 8, 31),
        categoryId: 2,
        createdAt: DateTime(2026, 8, 31),
        updatedAt: DateTime(2026, 8, 31),
      ),
    ];

    test('uses one inclusive range for totals and balance', () {
      final summary = const FinancialCalculationService().summary(
        transactions,
        range,
      );
      expect(summary.income, 5000000);
      expect(summary.expense, 200000);
      expect(summary.balance, 4800000);
    });

    test('groups spending by category and date', () {
      final service = const FinancialCalculationService();
      expect(service.categoryTotals(transactions, range), {
        2: 150000,
        3: 50000,
      });
      expect(service.dailyExpenses(transactions, range).single.amount, 200000);
    });
  });
}
