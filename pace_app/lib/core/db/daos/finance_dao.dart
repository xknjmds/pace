import 'package:drift/drift.dart';

import '../app_database.dart';

part 'finance_dao.g.dart';

@DriftAccessor(tables: [Expenses, Budgets])
class FinanceDao extends DatabaseAccessor<AppDatabase> with _$FinanceDaoMixin {
  FinanceDao(super.db);

  SimpleSelectStatement<$ExpensesTable, Expense> get _live => select(expenses)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]);

  Future<Expense> addExpense({
    required int amountMinor,
    required String category,
    String note = '',
    required DateTime spentAt,
  }) => into(expenses).insertReturning(
    ExpensesCompanion.insert(
      amountMinor: amountMinor,
      category: category,
      note: Value(note),
      spentAt: spentAt.toUtc(),
      updatedAt: db.now(),
    ),
  );

  Future<List<Expense>> getAll() => _live.get();

  Stream<List<Expense>> watchAll() => _live.watch();

  /// Expenses spent at or after [from] and before [to].
  Stream<List<Expense>> watchBetween(DateTime from, DateTime to) =>
      (_live..where(
            (t) =>
                t.spentAt.isBiggerOrEqualValue(from.toUtc()) &
                t.spentAt.isSmallerThanValue(to.toUtc()),
          ))
          .watch();

  Future<void> removeExpense(String id) =>
      (update(expenses)..where((t) => t.id.equals(id))).write(
        ExpensesCompanion(
          deletedAt: Value(db.now()),
          updatedAt: Value(db.now()),
        ),
      );

  SimpleSelectStatement<$BudgetsTable, Budget> get _budget => select(budgets)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
    ..limit(1);

  Future<Budget?> getBudget() => _budget.getSingleOrNull();

  Stream<Budget?> watchBudget() => _budget.watchSingleOrNull();

  /// Replaces the budget. Null clears it.
  Future<void> setBudget(BudgetPeriod? period, int amountMinor) =>
      transaction(() async {
        final now = db.now();
        await (update(budgets)..where((t) => t.deletedAt.isNull())).write(
          BudgetsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
        if (period == null) return;
        await into(budgets).insert(
          BudgetsCompanion.insert(
            period: period,
            amountMinor: amountMinor,
            updatedAt: now,
          ),
        );
      });
}
