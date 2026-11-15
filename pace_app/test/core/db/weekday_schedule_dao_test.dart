import 'package:flutter_test/flutter_test.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  test('upsert creates then replaces the row for a weekday', () async {
    final dao = t.db.weekdayScheduleDao;
    final mon = await dao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 7 * 60 + 30,
      commuteMinutes: 40,
      prepMinutes: 30,
    );
    expect(mon.id, isNotEmpty);
    expect(mon.firstClassMinutes, 450);

    t.tick();
    final again = await dao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: null,
      commuteMinutes: 40,
      prepMinutes: 30,
    );
    expect(again.id, mon.id);
    expect(again.firstClassMinutes, isNull);
    expect(again.updatedAt, t.now);
    expect((await dao.getAll()).length, 1);
  });

  test('clear soft-deletes and upsert revives the same row', () async {
    final dao = t.db.weekdayScheduleDao;
    final tue = await dao.upsert(
      weekday: DateTime.tuesday,
      firstClassMinutes: 8 * 60,
      commuteMinutes: 30,
      prepMinutes: 20,
    );
    await dao.clear(DateTime.tuesday);
    expect(await dao.getFor(DateTime.tuesday), isNull);
    expect(await dao.getAll(), isEmpty);

    final back = await dao.upsert(
      weekday: DateTime.tuesday,
      firstClassMinutes: 9 * 60,
      commuteMinutes: 30,
      prepMinutes: 20,
    );
    expect(back.id, tue.id);
    expect(back.deletedAt, isNull);
    expect((await dao.getFor(DateTime.tuesday))?.firstClassMinutes, 540);
  });

  test('getAll orders by weekday and watchAll follows changes', () async {
    final dao = t.db.weekdayScheduleDao;
    final seen = <List<int>>[];
    final sub = dao
        .watchAll()
        .map((rows) => rows.map((r) => r.weekday).toList())
        .listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    for (final d in [DateTime.friday, DateTime.monday]) {
      await dao.upsert(
        weekday: d,
        firstClassMinutes: null,
        commuteMinutes: 30,
        prepMinutes: 30,
      );
    }
    await pumpEventQueue();
    expect(seen.last, [DateTime.monday, DateTime.friday]);
  });
}
