import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/time/clock.dart';
import '../domain/budget_summary.dart';

final budgetProvider = StreamProvider<Budget?>(
  (ref) => ref.watch(appDatabaseProvider).financeDao.watchBudget(),
);

final expensesProvider = StreamProvider<List<Expense>>(
  (ref) => ref.watch(appDatabaseProvider).financeDao.watchAll(),
);

/// The budget's period, weekly when none is set.
final budgetPeriodProvider = Provider<Period>((ref) {
  final b = ref.watch(budgetProvider).value;
  return b?.period == BudgetPeriod.monthly ? Period.monthly : Period.weekly;
});

final budgetSummaryProvider = Provider<BudgetSummary>((ref) {
  final budget = ref.watch(budgetProvider).value;
  final expenses = ref.watch(expensesProvider).value ?? const <Expense>[];
  return budgetSummary(
    now: ref.watch(clockProvider)(),
    period: ref.watch(budgetPeriodProvider),
    budgetMinor: budget?.amountMinor,
    expenses: [
      for (final e in expenses)
        (amountMinor: e.amountMinor, category: e.category, spentAt: e.spentAt),
    ],
  );
});

/// Starter categories; anything typed in is fine too.
const expenseCategories = [
  'Food',
  'Transport',
  'School',
  'Fun',
  'Health',
  'Other',
];
