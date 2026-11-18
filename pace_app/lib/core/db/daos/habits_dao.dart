import 'package:drift/drift.dart';

import '../app_database.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [Habits, HabitLogs])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  static const defaultName = '10 minutes of movement';

  SimpleSelectStatement<$HabitsTable, Habit> get _live =>
      select(habits)..where((t) => t.deletedAt.isNull());

  /// The one habit PACE plans for, created (inactive) on first use.
  Future<Habit> ensureMovement() async {
    final existing = await (_live..limit(1)).getSingleOrNull();
    if (existing != null) return existing;
    return into(habits).insertReturning(
      HabitsCompanion.insert(
        name: defaultName,
        active: const Value(false),
        updatedAt: db.now(),
      ),
    );
  }

  Future<List<Habit>> getActive() =>
      (_live..where((t) => t.active.equals(true))).get();

  Stream<Habit?> watchMovement() => (_live..limit(1)).watchSingleOrNull();

  Future<void> edit(Habit habit) =>
      update(habits).replace(habit.copyWith(updatedAt: db.now()));

  SimpleSelectStatement<$HabitLogsTable, HabitLog> _log(
    String habitId,
    String key,
  ) => select(habitLogs)
    ..where(
      (t) =>
          t.habitId.equals(habitId) & t.date.equals(key) & t.deletedAt.isNull(),
    );

  Future<bool> isDone(String habitId, DateTime day) async =>
      (await _log(habitId, dateKey(day)).getSingleOrNull())?.done ?? false;

  Stream<bool> watchDone(String habitId, DateTime day) => _log(
    habitId,
    dateKey(day),
  ).watchSingleOrNull().map((l) => l?.done ?? false);

  /// Marks [day] done (or not). Re-uses the day's row, soft-deleted or not,
  /// so the unique key keeps holding.
  Future<void> setDone(String habitId, DateTime day, bool done) => transaction(
    () async {
      final key = dateKey(day);
      final now = db.now();
      final existing =
          await (select(habitLogs)
                ..where((t) => t.habitId.equals(habitId) & t.date.equals(key)))
              .getSingleOrNull();
      if (existing == null) {
        await into(habitLogs).insert(
          HabitLogsCompanion.insert(
            habitId: habitId,
            date: key,
            done: Value(done),
            updatedAt: now,
          ),
        );
        return;
      }
      await update(habitLogs).replace(
        existing.copyWith(
          done: done,
          updatedAt: now,
          deletedAt: const Value(null),
        ),
      );
    },
  );

  /// Done days for days [from] to [to] inclusive, as `yyyy-MM-dd` keys.
  Future<Set<String>> doneDaysBetween(DateTime from, DateTime to) async {
    final rows =
        await (select(habitLogs)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.done.equals(true) &
                  t.date.isBiggerOrEqualValue(dateKey(from)) &
                  t.date.isSmallerOrEqualValue(dateKey(to)),
            ))
            .get();
    return {for (final r in rows) r.date};
  }

  Stream<Set<String>> watchDoneDaysBetween(DateTime from, DateTime to) =>
      (select(habitLogs)..where(
            (t) =>
                t.deletedAt.isNull() &
                t.done.equals(true) &
                t.date.isBiggerOrEqualValue(dateKey(from)) &
                t.date.isSmallerOrEqualValue(dateKey(to)),
          ))
          .watch()
          .map((rows) => {for (final r in rows) r.date});
}
