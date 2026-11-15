import 'package:drift/drift.dart';

import '../app_database.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  SimpleSelectStatement<$TasksTable, Task> get _live => select(tasks)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]);

  Future<Task> add({
    required String title,
    String? subject,
    required DateTime dueAt,
    TaskSource source = TaskSource.manual,
  }) {
    final now = db.now();
    return into(tasks).insertReturning(
      TasksCompanion.insert(
        title: title,
        subject: Value(subject),
        dueAt: dueAt.toUtc(),
        source: Value(source),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Task?> getById(String id) =>
      (_live..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Task>> getAll() => _live.get();

  Stream<List<Task>> watchPending() =>
      (_live..where((t) => t.status.equalsValue(TaskStatus.pending))).watch();

  /// Pending tasks due at or before [instant], soonest first.
  Future<List<Task>> pendingDueBy(DateTime instant) =>
      (_live..where(
            (t) =>
                t.status.equalsValue(TaskStatus.pending) &
                t.dueAt.isSmallerOrEqualValue(instant.toUtc()),
          ))
          .get();

  /// Saves edits to title, subject or due time. Stamps `updated_at`.
  Future<void> edit(Task task) => update(
    tasks,
  ).replace(task.copyWith(dueAt: task.dueAt.toUtc(), updatedAt: db.now()));

  Future<void> setStatus(String id, TaskStatus status) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(status: Value(status), updatedAt: Value(db.now())),
      );

  Future<void> markSubmitted(String id) => setStatus(id, TaskStatus.submitted);

  Future<void> remove(String id) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(deletedAt: Value(db.now()), updatedAt: Value(db.now())),
      );
}
