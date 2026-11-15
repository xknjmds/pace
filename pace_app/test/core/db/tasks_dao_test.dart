import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  test('add stores a pending manual task with UTC due time', () async {
    final due = DateTime(2026, 11, 20, 23, 59);
    final task = await t.db.tasksDao.add(
      title: 'Essay',
      subject: 'English',
      dueAt: due,
    );
    expect(task.status, TaskStatus.pending);
    expect(task.source, TaskSource.manual);
    expect(task.dueAt.isUtc, isTrue);
    expect(task.dueAt, due.toUtc());
    expect(task.createdAt, t.now);
    expect(await t.db.tasksDao.getById(task.id), task);
  });

  test('markSubmitted leaves the pending list and bumps updatedAt', () async {
    final dao = t.db.tasksDao;
    final a = await dao.add(title: 'A', dueAt: DateTime.utc(2026, 11, 16));
    final b = await dao.add(title: 'B', dueAt: DateTime.utc(2026, 11, 15));
    t.tick();
    await dao.markSubmitted(a.id);
    final pending = await dao.watchPending().first;
    expect(pending.map((x) => x.id), [b.id]);
    final after = await dao.getById(a.id);
    expect(after!.status, TaskStatus.submitted);
    expect(after.updatedAt, t.now);
  });

  test('pendingDueBy returns soonest first and skips submitted', () async {
    final dao = t.db.tasksDao;
    final late = await dao.add(
      title: 'late',
      dueAt: DateTime.utc(2026, 11, 18),
    );
    final soon = await dao.add(
      title: 'soon',
      dueAt: DateTime.utc(2026, 11, 15),
    );
    final done = await dao.add(
      title: 'done',
      dueAt: DateTime.utc(2026, 11, 14),
    );
    await dao.markSubmitted(done.id);
    final rows = await dao.pendingDueBy(DateTime.utc(2026, 11, 18));
    expect(rows.map((x) => x.id), [soon.id, late.id]);
    expect(await dao.pendingDueBy(DateTime.utc(2026, 11, 16)), hasLength(1));
  });

  test('edit saves title and due time', () async {
    final dao = t.db.tasksDao;
    final task = await dao.add(
      title: 'Draft',
      dueAt: DateTime.utc(2026, 11, 16),
    );
    await dao.edit(
      task.copyWith(title: 'Final', dueAt: DateTime.utc(2026, 11, 17, 8)),
    );
    final after = await dao.getById(task.id);
    expect(after!.title, 'Final');
    expect(after.dueAt, DateTime.utc(2026, 11, 17, 8));
  });

  test('remove is a soft delete hidden from every read', () async {
    final dao = t.db.tasksDao;
    final task = await dao.add(title: 'X', dueAt: DateTime.utc(2026, 11, 16));
    await dao.remove(task.id);
    expect(await dao.getById(task.id), isNull);
    expect(await dao.getAll(), isEmpty);
    expect(await dao.watchPending().first, isEmpty);
    final raw = await t.db.select(t.db.tasks).get();
    expect(raw.single.deletedAt, t.now);
  });
}
