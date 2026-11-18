import 'package:flutter_test/flutter_test.dart';
import 'package:pace/features/finance/domain/budget_summary.dart';
import 'package:pace/features/finance/domain/money.dart';

void main() {
  group('money', () {
    test('parses amounts into minor units', () {
      expect(parseAmount('12'), 1200);
      expect(parseAmount('12.5'), 1250);
      expect(parseAmount('1,250.05'), 125005);
      expect(parseAmount('0'), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('1.234'), isNull);
    });

    test('formats with grouping and an optional code', () {
      expect(formatMoney(125005), '1,250.05');
      expect(formatMoney(5, 'php'), '0.05 PHP');
    });
  });

  group('budget summary', () {
    final now = DateTime(2026, 11, 18, 12); // Wednesday
    SpendRecord e(int minor, String c, DateTime at) =>
        (amountMinor: minor, category: c, spentAt: at);

    test('weekly period runs Monday to Monday', () {
      final b = periodBounds(now, Period.weekly);
      expect(b.from, DateTime(2026, 11, 16));
      expect(b.to, DateTime(2026, 11, 23));
    });

    test('monthly period across a year boundary', () {
      final b = periodBounds(DateTime(2026, 12, 31), Period.monthly);
      expect(b.from, DateTime(2026, 12));
      expect(b.to, DateTime(2027, 1));
    });

    test('totals only the current period, by category', () {
      final s = budgetSummary(
        now: now,
        period: Period.weekly,
        budgetMinor: 100000,
        expenses: [
          e(2000, 'Food', DateTime(2026, 11, 16, 0, 0)),
          e(3000, 'Food', DateTime(2026, 11, 18)),
          e(1500, 'Transport', DateTime(2026, 11, 22, 23, 59)),
          e(9999, 'Food', DateTime(2026, 11, 15, 23, 59)), // last week
          e(9999, 'Food', DateTime(2026, 11, 23)), // next week
        ],
      );
      expect(s.spentMinor, 6500);
      expect(s.byCategory.first, (category: 'Food', amountMinor: 5000));
      expect(s.remainingMinor, 93500);
      expect(s.overBudget, isFalse);
    });

    test('no budget set and no expenses', () {
      final s = budgetSummary(
        now: now,
        period: Period.monthly,
        expenses: const [],
      );
      expect(s.spentMinor, 0);
      expect(s.remainingMinor, isNull);
      expect(s.byCategory, isEmpty);
      expect(describeBudget(s, formatMoney), contains('No budget set'));
    });

    test('over budget is described neutrally', () {
      final s = budgetSummary(
        now: now,
        period: Period.weekly,
        budgetMinor: 1000,
        expenses: [e(1500, 'Food', now)],
      );
      expect(s.overBudget, isTrue);
      expect(
        describeBudget(s, formatMoney),
        '5.00 past the budget. A new period starts soon.',
      );
    });
  });
}
