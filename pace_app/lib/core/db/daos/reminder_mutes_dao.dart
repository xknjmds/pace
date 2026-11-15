import 'package:drift/drift.dart';

import '../app_database.dart';

part 'reminder_mutes_dao.g.dart';

/// "Not today": silences one reminder owner for one local day without
/// marking anything done or logging a miss.
@DriftAccessor(tables: [ReminderMutes])
class ReminderMutesDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderMutesDaoMixin {
  ReminderMutesDao(super.db);

  Future<ReminderMute?> _any(ReminderKind kind, String ownerId, String key) =>
      (select(reminderMutes)..where(
            (t) =>
                t.kind.equalsValue(kind) &
                t.ownerId.equals(ownerId) &
                t.date.equals(key),
          ))
          .getSingleOrNull();

  /// Idempotent. Revives a soft-deleted mute rather than violating the key.
  Future<ReminderMute> mute(
    ReminderKind kind,
    String ownerId,
    DateTime day,
  ) async {
    final key = dateKey(day);
    final now = db.now();
    final existing = await _any(kind, ownerId, key);
    if (existing == null) {
      return into(reminderMutes).insertReturning(
        ReminderMutesCompanion.insert(
          kind: kind,
          ownerId: ownerId,
          date: key,
          updatedAt: now,
        ),
      );
    }
    final next = existing.copyWith(
      updatedAt: now,
      deletedAt: const Value(null),
    );
    await update(reminderMutes).replace(next);
    return next;
  }

  Future<void> unmute(ReminderKind kind, String ownerId, DateTime day) =>
      (update(reminderMutes)..where(
            (t) =>
                t.kind.equalsValue(kind) &
                t.ownerId.equals(ownerId) &
                t.date.equals(dateKey(day)),
          ))
          .write(
            ReminderMutesCompanion(
              deletedAt: Value(db.now()),
              updatedAt: Value(db.now()),
            ),
          );

  Future<bool> isMuted(ReminderKind kind, String ownerId, DateTime day) async {
    final row = await _any(kind, ownerId, dateKey(day));
    return row != null && row.deletedAt == null;
  }

  /// Live mutes for days [from] to [to] inclusive.
  Future<List<ReminderMute>> between(DateTime from, DateTime to) =>
      (select(reminderMutes)..where(
            (t) =>
                t.deletedAt.isNull() &
                t.date.isBiggerOrEqualValue(dateKey(from)) &
                t.date.isSmallerOrEqualValue(dateKey(to)),
          ))
          .get();

  Future<List<ReminderMute>> mutesOn(DateTime day) => (select(
    reminderMutes,
  )..where((t) => t.date.equals(dateKey(day)) & t.deletedAt.isNull())).get();
}
