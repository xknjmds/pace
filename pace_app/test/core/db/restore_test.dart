import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

/// Every delete the UI offers to undo can be undone in the DAO.
void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  test('a removed task comes back with updated_at bumped', () async {
    final dao = t.db.tasksDao;
    final task = await dao.add(title: 'Essay', dueAt: DateTime(2026, 11, 20));
    await dao.remove(task.id);
    t.tick();
    await dao.restore(task.id);
    final back = (await dao.getAll()).single;
    expect(back.id, task.id);
    expect(back.deletedAt, isNull);
    expect(back.updatedAt, t.now);
  });

  test('a removed inbox item comes back', () async {
    final dao = t.db.inboxDao;
    final item = await dao.add('maybe later');
    await dao.remove(item.id);
    await dao.restore(item.id);
    expect((await dao.getUnprocessed()).single.id, item.id);
  });

  test('a removed class block comes back', () async {
    final dao = t.db.classBlocksDao;
    final b = await dao.add(
      weekday: 3,
      subject: 'Art',
      startMinutes: 600,
      endMinutes: 660,
    );
    await dao.remove(b.id);
    await dao.restore(b.id);
    expect((await dao.getAll()).single.id, b.id);
  });

  test('a removed expense comes back', () async {
    final dao = t.db.financeDao;
    final e = await dao.addExpense(
      amountMinor: 1250,
      category: 'Food',
      spentAt: DateTime(2026, 11, 18, 12),
    );
    await dao.removeExpense(e.id);
    await dao.restoreExpense(e.id);
    expect((await dao.getAll()).single.id, e.id);
  });
}
