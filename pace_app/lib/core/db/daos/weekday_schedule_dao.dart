import 'package:drift/drift.dart';

import '../app_database.dart';

part 'weekday_schedule_dao.g.dart';

@DriftAccessor(tables: [WeekdaySchedules])
class WeekdayScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$WeekdayScheduleDaoMixin {
  WeekdayScheduleDao(super.db);

  SimpleSelectStatement<$WeekdaySchedulesTable, WeekdaySchedule> get _live =>
      select(weekdaySchedules)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.weekday)]);

  Future<List<WeekdaySchedule>> getAll() => _live.get();

  Stream<List<WeekdaySchedule>> watchAll() => _live.watch();

  /// [weekday] is [DateTime.monday] to [DateTime.sunday].
  Future<WeekdaySchedule?> getFor(int weekday) =>
      (_live..where((t) => t.weekday.equals(weekday))).getSingleOrNull();

  /// Creates or replaces the row for [weekday]. A soft-deleted row for that
  /// weekday is revived so the unique key keeps holding.
  Future<WeekdaySchedule> upsert({
    required int weekday,
    required int? firstClassMinutes,
    required int commuteMinutes,
    required int prepMinutes,
  }) async {
    assert(weekday >= DateTime.monday && weekday <= DateTime.sunday);
    final now = db.now();
    final existing = await (select(
      weekdaySchedules,
    )..where((t) => t.weekday.equals(weekday))).getSingleOrNull();
    if (existing == null) {
      return into(weekdaySchedules).insertReturning(
        WeekdaySchedulesCompanion.insert(
          weekday: weekday,
          firstClassMinutes: Value(firstClassMinutes),
          commuteMinutes: Value(commuteMinutes),
          prepMinutes: Value(prepMinutes),
          updatedAt: now,
        ),
      );
    }
    final next = existing.copyWith(
      firstClassMinutes: Value(firstClassMinutes),
      commuteMinutes: commuteMinutes,
      prepMinutes: prepMinutes,
      updatedAt: now,
      deletedAt: const Value(null),
    );
    await update(weekdaySchedules).replace(next);
    return next;
  }

  /// Forgets the schedule for [weekday] (soft delete).
  Future<void> clear(int weekday) =>
      (update(weekdaySchedules)..where((t) => t.weekday.equals(weekday))).write(
        WeekdaySchedulesCompanion(
          deletedAt: Value(db.now()),
          updatedAt: Value(db.now()),
        ),
      );
}
