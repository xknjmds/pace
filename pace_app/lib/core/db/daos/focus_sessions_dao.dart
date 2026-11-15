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

  /// Marks the session finished. Pass [durationMinutes] when the owner
  /// stopped early or kept going, so the record holds the real length.
  Future<void> complete(String id, {int? durationMinutes}) =>
      (update(focusSessions)..where((t) => t.id.equals(id))).write(
        FocusSessionsCompanion(
          completed: const Value(true),
          durationMinutes: durationMinutes == null
              ? const Value.absent()
              : Value(durationMinutes),
          updatedAt: Value(db.now()),
        ),
      );

  Future<List<FocusSession>> recent({int limit = 20}) =>
      (_live..limit(limit)).get();

  Future<void> remove(String id) =>
      (update(focusSessions)..where((t) => t.id.equals(id))).write(
        FocusSessionsCompanion(
          deletedAt: Value(db.now()),
          updatedAt: Value(db.now()),
        ),
      );
}
