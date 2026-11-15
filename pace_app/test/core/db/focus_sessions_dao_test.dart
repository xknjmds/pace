import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  test('start then complete records the real duration', () async {
    final dao = t.db.focusSessionsDao;
    final s = await dao.start(
      taskId: 'task-1',
      startedAt: DateTime(2026, 11, 14, 19),
      durationMinutes: 10,
    );
    expect(s.completed, isFalse);
    expect(s.startedAt.isUtc, isTrue);
    t.tick(const Duration(minutes: 14));
    await dao.complete(s.id, durationMinutes: 14);
    final after = await dao.getById(s.id);
    expect(after!.completed, isTrue);
    expect(after.durationMinutes, 14);
    expect(after.updatedAt, t.now);
  });

  test('recent lists newest first and hides removed sessions', () async {
    final dao = t.db.focusSessionsDao;
    final old = await dao.start(
      startedAt: DateTime.utc(2026, 11, 13, 19),
      durationMinutes: 10,
    );
    final newer = await dao.start(
      startedAt: DateTime.utc(2026, 11, 14, 19),
      durationMinutes: 10,
    );
    expect((await dao.recent()).map((s) => s.id), [newer.id, old.id]);
    await dao.remove(newer.id);
    expect((await dao.recent()).map((s) => s.id), [old.id]);
  });
}
