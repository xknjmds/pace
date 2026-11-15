import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  test('dateKey uses the local calendar day', () {
    expect(dateKey(DateTime(2026, 1, 5, 23, 30)), '2026-01-05');
    expect(dateKey(DateTime(2026, 11, 14)), '2026-11-14');
  });

  test('a day with nothing logged has no row', () async {
    expect(await t.db.dailyLogsDao.get(DateTime(2026, 11, 14)), isNull);
  });

  test('writes create the row and accumulate', () async {
    final dao = t.db.dailyLogsDao;
    final day = DateTime(2026, 11, 14);
    await dao.logWake(day, DateTime(2026, 11, 14, 6, 42));
    await dao.setTop3(day, ['a', 'b']);
    t.tick();
    final log = await dao.setRoutineDone(day, true);
    expect(log.date, '2026-11-14');
    expect(log.wakeLoggedAt, DateTime(2026, 11, 14, 6, 42).toUtc());
    expect(log.top3TaskIds, ['a', 'b']);
    expect(log.routineDone, isTrue);
    expect(log.bedLoggedAt, isNull);
    expect(log.updatedAt, t.now);
    // Data classes compare list columns by identity, so check fields.
    final watched = await dao.watch(day).first;
    expect(watched?.top3TaskIds, ['a', 'b']);
    expect(watched?.routineDone, isTrue);
  });

  test('between returns the inclusive range oldest first', () async {
    final dao = t.db.dailyLogsDao;
    for (final d in [13, 15, 14, 12]) {
      await dao.setRoutineDone(DateTime(2026, 11, d), true);
    }
    final rows = await dao.between(
      DateTime(2026, 11, 13),
      DateTime(2026, 11, 15),
    );
    expect(rows.map((r) => r.date), ['2026-11-13', '2026-11-14', '2026-11-15']);
  });
}
