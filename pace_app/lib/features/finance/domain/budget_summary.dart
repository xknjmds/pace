import '../../../core/time/date_key.dart';

enum Period { weekly, monthly }

/// The current period holding [now]: Monday to Monday, or the calendar
/// month. Local days; `to` is exclusive.
({DateTime from, DateTime to}) periodBounds(DateTime now, Period period) {
  final d = dateOnly(now);
  return switch (period) {
    Period.weekly => (
      from: DateTime(d.year, d.month, d.day - (d.weekday - 1)),
      to: DateTime(d.year, d.month, d.day - (d.weekday - 1) + 7),
    ),
    Period.monthly => (
      from: DateTime(d.year, d.month),
      to: DateTime(d.year, d.month + 1),
    ),
  };
}

/// An expense as the summary needs it.
typedef SpendRecord = ({int amountMinor, String category, DateTime spentAt});

class BudgetSummary {
  const BudgetSummary({
    required this.from,
    required this.to,
    required this.spentMinor,
    required this.budgetMinor,
    required this.byCategory,
  });

  final DateTime from;
  final DateTime to;
  final int spentMinor;

  /// Null when no budget is set.
  final int? budgetMinor;

  /// Category totals, largest first.
  final List<({String category, int amountMinor})> byCategory;

  /// What is left; negative once past the budget. Null without a budget.
  int? get remainingMinor =>
      budgetMinor == null ? null : budgetMinor! - spentMinor;

  bool get overBudget => budgetMinor != null && spentMinor > budgetMinor!;
}

/// Pure: totals for the period holding [now]. Instants are compared in
/// local time, so a purchase at 23:30 counts on that day.
BudgetSummary budgetSummary({
  required DateTime now,
  required Period period,
  required List<SpendRecord> expenses,
  int? budgetMinor,
}) {
  final b = periodBounds(now, period);
  final inPeriod = [
    for (final e in expenses)
      if (_within(e.spentAt, b.from, b.to)) e,
  ];
  final totals = <String, int>{};
  for (final e in inPeriod) {
    totals[e.category] = (totals[e.category] ?? 0) + e.amountMinor;
  }
  final byCategory = [
    for (final e in totals.entries) (category: e.key, amountMinor: e.value),
  ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
  return BudgetSummary(
    from: b.from,
    to: b.to,
    spentMinor: inPeriod.fold(0, (a, e) => a + e.amountMinor),
    budgetMinor: budgetMinor,
    byCategory: byCategory,
  );
}

bool _within(DateTime t, DateTime from, DateTime to) {
  final l = t.isUtc ? t.toLocal() : t;
  return !l.isBefore(from) && l.isBefore(to);
}

/// Neutral words for where the period stands. Never alarming.
String describeBudget(BudgetSummary s, String Function(int) money) {
  final remaining = s.remainingMinor;
  if (remaining == null) return 'No budget set. Spending is still counted.';
  if (remaining >= 0) return '${money(remaining)} left this period';
  return '${money(-remaining)} past the budget. A new period starts soon.';
}
