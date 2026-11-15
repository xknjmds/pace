import 'package:drift/drift.dart';

import '../app_database.dart';

part 'daily_logs_dao.g.dart';

/// One row per local calendar day. Rows are created on first write, so a
/// day with nothing logged simply has no row.
@DriftAccessor(tables: [DailyLogs])
class DailyLogsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyLogsDaoMixin {
  DailyLogsDao(super.db);

  SimpleSelectStatement<$DailyLogsTable, DailyLog> _row(String key) =>
      select(dailyLogs)
        ..where((t) => t.date.equals(key) & t.deletedAt.isNull());

  Future<DailyLog?> get(DateTime day) => _row(dateKey(day)).getSingleOrNull();

  Stream<DailyLog?> watch(DateTime day) =>
      _row(dateKey(day)).watchSingleOrNull();

  /// Logs for days [from] to [to] inclusive, oldest first.
  Future<List<DailyLog>> between(DateTime from, DateTime to) =>
      (select(dailyLogs)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.date.isBiggerOrEqualValue(dateKey(from)) &
                  t.date.isSmallerOrEqualValue(dateKey(to)),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  /// Applies [change] to the day's row, creating it first if needed.
  Future<DailyLog> change(
    DateTime day,
    DailyLogsCompanion Function(DailyLog current) change,
  ) => transaction(() async {
    final key = dateKey(day);
    final now = db.now();
    var current = await _row(key).getSingleOrNull();
    current ??= await into(
      dailyLogs,
    ).insertReturning(DailyLogsCompanion.insert(date: key, updatedAt: now));
    final patch = change(current).copyWith(updatedAt: Value(now));
    await (update(dailyLogs)..where((t) => t.date.equals(key))).write(patch);
    return _row(key).getSingle();
  });

  Future<DailyLog> setTop3(DateTime day, List<String> taskIds) {
    assert(taskIds.length <= 3, 'top 3 means at most three');
    return change(day, (_) => DailyLogsCompanion(top3TaskIds: Value(taskIds)));
  }

  Future<DailyLog> logBed(DateTime day, DateTime at) =>
      change(day, (_) => DailyLogsCompanion(bedLoggedAt: Value(at.toUtc())));

  Future<DailyLog> logWake(DateTime day, DateTime at) =>
      change(day, (_) => DailyLogsCompanion(wakeLoggedAt: Value(at.toUtc())));

  Future<DailyLog> logEat(DateTime day, DateTime at) =>
      change(day, (_) => DailyLogsCompanion(eatDoneAt: Value(at.toUtc())));

  Future<DailyLog> setRoutineDone(DateTime day, bool done) =>
      change(day, (_) => DailyLogsCompanion(routineDone: Value(done)));
}
