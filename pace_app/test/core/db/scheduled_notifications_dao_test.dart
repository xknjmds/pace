import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';

import 'test_db.dart';

void main() {
  late TestDb t;
  setUp(() => t = TestDb());
  tearDown(() => t.close());

  ReminderDraft draft(int hour) => (
    fireAt: DateTime.utc(2026, 11, 15, hour),
    title: 'T$hour',
    body: 'B$hour',
  );

  test('insertAll hands out increasing ids from the reserved floor', () async {
    final dao = t.db.scheduledNotificationsDao;
    final rows = await dao.insertAll(ReminderKind.wake, '1', [
      draft(6),
      draft(7),
    ]);
    expect(rows.map((r) => r.notificationId), [
      ScheduledNotificationsDao.firstNotificationId,
      ScheduledNotificationsDao.firstNotificationId + 1,
    ]);
    expect(rows.first.title, 'T6');
    expect(rows.first.fireAt, DateTime.utc(2026, 11, 15, 6));
  });

  test('ids are never reused after a soft delete', () async {
    final dao = t.db.scheduledNotificationsDao;
    await dao.insertAll(ReminderKind.wake, '1', [draft(6)]);
    await dao.softDeleteByOwner(ReminderKind.wake, '1');
    final next = await dao.insertAll(ReminderKind.wake, '1', [draft(6)]);
    expect(
      next.single.notificationId,
      ScheduledNotificationsDao.firstNotificationId + 1,
    );
    expect(await dao.getLive(), hasLength(1));
  });

  test('byOwner and softDeleteByOwner touch only that owner', () async {
    final dao = t.db.scheduledNotificationsDao;
    await dao.insertAll(ReminderKind.deadline, 'task-a', [draft(9), draft(10)]);
    await dao.insertAll(ReminderKind.deadline, 'task-b', [draft(9)]);
    await dao.insertAll(ReminderKind.wake, 'task-a', [draft(6)]);

    expect(await dao.byOwner(ReminderKind.deadline, 'task-a'), hasLength(2));
    await dao.softDeleteByOwner(ReminderKind.deadline, 'task-a');
    expect(await dao.byOwner(ReminderKind.deadline, 'task-a'), isEmpty);
    expect(await dao.byOwner(ReminderKind.deadline, 'task-b'), hasLength(1));
    expect(await dao.byOwner(ReminderKind.wake, 'task-a'), hasLength(1));
    expect(await dao.getLive(), hasLength(2));
  });

  test('getLive is ordered by fire time', () async {
    final dao = t.db.scheduledNotificationsDao;
    await dao.insertAll(ReminderKind.leave, '1', [draft(8), draft(7)]);
    expect((await dao.getLive()).map((r) => r.title), ['T7', 'T8']);
  });
}
