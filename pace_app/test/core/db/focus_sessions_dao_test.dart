import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  test('a started session is active until finished', () async {
    final dao = t.db.focusSessionsDao;
    expect(await dao.getActive(), isNull);
    final s = await dao.start(
      taskId: 'task-1',
      startedAt: DateTime(2026, 11, 14, 19),
      durationMinutes: 10,
    );
    expect(s.startedAt.isUtc, isTrue);
    expect(s.endedAt, isNull);
    expect((await dao.getActive())?.id, s.id);

    t.tick(const Duration(minutes: 14));
    await dao.finish(
      s.id,
      durationMinutes: 10,
      completed: true,
      endedAt: DateTime(2026, 11, 14, 19, 14),
    );
    expect(await dao.getActive(), isNull);
    final after = await dao.getById(s.id);
    expect(after!.completed, isTrue);
    expect(after.durationMinutes, 10);
    expect(after.endedAt, DateTime(2026, 11, 14, 19, 14).toUtc());
    expect(after.updatedAt, t.now);
  });

  test('recent lists ended sessions newest first, hides removed', () async {
    final dao = t.db.focusSessionsDao;
    final old = await dao.start(
      startedAt: DateTime.utc(2026, 11, 13, 19),
      durationMinutes: 10,
    );
    final newer = await dao.start(
      startedAt: DateTime.utc(2026, 11, 14, 19),
      durationMinutes: 10,
    );
    final live = await dao.start(
      startedAt: DateTime.utc(2026, 11, 14, 20),
      durationMinutes: 10,
    );
    for (final s in [old, newer]) {
      await dao.finish(
        s.id,
        durationMinutes: 10,
        completed: true,
        endedAt: s.startedAt.add(const Duration(minutes: 10)),
      );
    }
    expect((await dao.recent()).map((s) => s.id), [newer.id, old.id]);
    expect((await dao.getActive())?.id, live.id);
    await dao.remove(newer.id);
    expect((await dao.recent()).map((s) => s.id), [old.id]);
  });
}
