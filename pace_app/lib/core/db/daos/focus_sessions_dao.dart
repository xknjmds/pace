import 'package:drift/drift.dart';

import '../app_database.dart';

part 'focus_sessions_dao.g.dart';

@DriftAccessor(tables: [FocusSessions])
class FocusSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$FocusSessionsDaoMixin {
  FocusSessionsDao(super.db);

  SimpleSelectStatement<$FocusSessionsTable, FocusSession> get _live =>
      select(focusSessions)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);

  SimpleSelectStatement<$FocusSessionsTable, FocusSession> get _active => _live
    ..where((t) => t.endedAt.isNull())
    ..limit(1);

  Future<FocusSession> start({
    String? taskId,
    required DateTime startedAt,
    required int durationMinutes,
  }) {
    final now = db.now();
    return into(focusSessions).insertReturning(
      FocusSessionsCompanion.insert(
        taskId: Value(taskId),
        startedAt: startedAt.toUtc(),
        durationMinutes: durationMinutes,
        updatedAt: now,
      ),
    );
  }

  Future<FocusSession?> getById(String id) =>
      (_live..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The session not yet ended, if any. There is at most one.
  Future<FocusSession?> getActive() => _active.getSingleOrNull();

  Stream<FocusSession?> watchActive() => _active.watchSingleOrNull();

  /// Ends the session with the minutes actually spent.
  Future<void> finish(
    String id, {
    required int durationMinutes,
    required bool completed,
    required DateTime endedAt,
  }) => (update(focusSessions)..where((t) => t.id.equals(id))).write(
    FocusSessionsCompanion(
      durationMinutes: Value(durationMinutes),
      completed: Value(completed),
      endedAt: Value(endedAt.toUtc()),
      updatedAt: Value(db.now()),
    ),
  );

  /// Ended sessions, newest first.
  Future<List<FocusSession>> recent({int limit = 20}) =>
      (_live
            ..where((t) => t.endedAt.isNotNull())
            ..limit(limit))
          .get();

  Future<void> remove(String id) =>
      (update(focusSessions)..where((t) => t.id.equals(id))).write(
        FocusSessionsCompanion(
          deletedAt: Value(db.now()),
          updatedAt: Value(db.now()),
        ),
      );
}
