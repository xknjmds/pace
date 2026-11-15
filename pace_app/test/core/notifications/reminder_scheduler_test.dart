import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/notifications/reminder_scheduler.dart';

import '../db/test_db.dart';
import 'fake_notification_gateway.dart';

void main() {
  late TestDb t;
  late FakeNotificationGateway gateway;
  late ReminderScheduler scheduler;

  setUp(() {
    t = TestDb(DateTime.utc(2026, 11, 14, 6));
    gateway = FakeNotificationGateway();
    scheduler = ReminderScheduler(db: t.db, gateway: gateway, now: () => t.now);
  });
  tearDown(() => t.close());

  ReminderDraft at(DateTime fireAt, [String title = 'r']) =>
      (fireAt: fireAt, title: title, body: 'body');

  test('replaceOwner stores rows and hands the same ids to Android', () async {
    final rows = await scheduler.replaceOwner(ReminderKind.deadline, 'task-1', [
      at(DateTime.utc(2026, 11, 15, 8), 'tomorrow'),
      at(DateTime.utc(2026, 11, 13, 8), 'already past'),
    ]);
    expect(rows.map((r) => r.title), ['tomorrow']);
    expect(gateway.scheduled.keys, [rows.single.notificationId]);
    expect(
      gateway.scheduled.values.single.fireAt,
      DateTime.utc(2026, 11, 15, 8),
    );
  });

  test('replaceOwner cancels the old reminders first', () async {
    final first = await scheduler.replaceOwner(ReminderKind.wake, '1', [
      at(DateTime.utc(2026, 11, 15, 6)),
    ]);
    final second = await scheduler.replaceOwner(ReminderKind.wake, '1', [
      at(DateTime.utc(2026, 11, 15, 6, 30)),
    ]);
    expect(gateway.cancelled, [first.single.notificationId]);
    expect(gateway.scheduled.keys, [second.single.notificationId]);
    expect(await t.db.scheduledNotificationsDao.getLive(), hasLength(1));
  });

  test(
    'cancelOwner removes every pending reminder for that owner only',
    () async {
      await scheduler.replaceOwner(ReminderKind.deadline, 'task-1', [
        at(DateTime.utc(2026, 11, 15, 8)),
        at(DateTime.utc(2026, 11, 16, 8)),
      ]);
      final keep = await scheduler.replaceOwner(
        ReminderKind.deadline,
        'task-2',
        [at(DateTime.utc(2026, 11, 15, 8))],
      );
      await scheduler.cancelOwner(ReminderKind.deadline, 'task-1');
      expect(gateway.scheduled.keys, [keep.single.notificationId]);
      expect(gateway.cancelled, hasLength(2));
      expect(
        await t.db.scheduledNotificationsDao.byOwner(
          ReminderKind.deadline,
          'task-1',
        ),
        isEmpty,
      );
    },
  );

  test('rebuildAll drops past rows and re-schedules future ones', () async {
    final rows = await scheduler.replaceOwner(ReminderKind.leave, '1', [
      at(DateTime.utc(2026, 11, 14, 7), 'soon'),
      at(DateTime.utc(2026, 11, 15, 7), 'tomorrow'),
    ]);
    // Simulate a reboot: Android lost everything, time moved past the first.
    gateway.scheduled.clear();
    gateway.scheduled[4242] = (
      title: 'stale',
      body: '',
      fireAt: DateTime.utc(2026, 11, 20),
      payload: null,
      actions: const [],
    );
    t.now = DateTime.utc(2026, 11, 14, 8);

    await scheduler.rebuildAll();

    final tomorrow = rows.firstWhere((r) => r.title == 'tomorrow');
    expect(gateway.scheduled.keys, [tomorrow.notificationId]);
    expect(gateway.cancelled, contains(4242));
    final live = await t.db.scheduledNotificationsDao.getLive();
    expect(live.map((r) => r.title), ['tomorrow']);
  });
}
