import 'package:drift/drift.dart';

import '../app_database.dart';

part 'check_ins_dao.g.dart';

/// How each routine step went, one live row per day and step.
@DriftAccessor(tables: [CheckIns])
class CheckInsDao extends DatabaseAccessor<AppDatabase>
    with _$CheckInsDaoMixin {
  CheckInsDao(super.db);

  SimpleSelectStatement<$CheckInsTable, CheckIn> _live(String key) =>
      select(checkIns)..where((t) => t.day.equals(key) & t.deletedAt.isNull());

  /// The day's check-ins, keyed by step.
  Stream<Map<ReminderKind, CheckIn>> watchDay(DateTime day) => _live(
    dateKey(day),
  ).watch().map((rows) => {for (final r in rows) r.kind: r});

  Future<CheckIn?> get(DateTime day, ReminderKind kind) => (_live(
    dateKey(day),
  )..where((t) => t.kind.equalsValue(kind))).getSingleOrNull();

  /// Check-ins for days [from] to [to] inclusive.
  Future<List<CheckIn>> between(DateTime from, DateTime to) =>
      (select(checkIns)..where(
            (t) =>
                t.deletedAt.isNull() &
                t.day.isBiggerOrEqualValue(dateKey(from)) &
                t.day.isSmallerOrEqualValue(dateKey(to)),
          ))
          .get();

  /// Live version of [between].
  Stream<List<CheckIn>> watchBetween(DateTime from, DateTime to) =>
      (select(checkIns)..where(
            (t) =>
                t.deletedAt.isNull() &
                t.day.isBiggerOrEqualValue(dateKey(from)) &
                t.day.isSmallerOrEqualValue(dateKey(to)),
          ))
          .watch();

  /// Records how [kind] went on [day]. Re-uses the day's row, soft-deleted
  /// or not, so the unique key keeps holding.
  Future<void> record(
    DateTime day,
    ReminderKind kind,
    CheckInOutcome outcome, {
    DateTime? actualAt,
    String? reason,
  }) => transaction(() async {
    final key = dateKey(day);
    final now = db.now();
    final note = reason?.trim();
    final existing =
        await (select(checkIns)
              ..where((t) => t.day.equals(key) & t.kind.equalsValue(kind)))
            .getSingleOrNull();
    if (existing == null) {
      await into(checkIns).insert(
        CheckInsCompanion.insert(
          day: key,
          kind: kind,
          outcome: outcome,
          actualAt: Value(actualAt?.toUtc()),
          reason: Value(note == null || note.isEmpty ? null : note),
          updatedAt: now,
        ),
      );
      return;
    }
    await update(checkIns).replace(
      existing.copyWith(
        outcome: outcome,
        actualAt: Value(actualAt?.toUtc()),
        reason: Value(note == null || note.isEmpty ? null : note),
        updatedAt: now,
        deletedAt: const Value(null),
      ),
    );
  });

  /// Clears the day's check-in for [kind] (soft delete).
  Future<void> clear(DateTime day, ReminderKind kind) =>
      (update(checkIns)..where(
            (t) =>
                t.day.equals(dateKey(day)) &
                t.kind.equalsValue(kind) &
                t.deletedAt.isNull(),
          ))
          .write(
            CheckInsCompanion(
              deletedAt: Value(db.now()),
              updatedAt: Value(db.now()),
            ),
          );
}
