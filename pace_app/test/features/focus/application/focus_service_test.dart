import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/notifications/reminder_actions.dart';
import 'package:pace/core/notifications/reminder_scheduler.dart';
import 'package:pace/features/focus/application/focus_service.dart';

import '../../../core/db/test_db.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  final start = DateTime(2026, 11, 14, 19);
  late TestDb t;
  late FakeNotificationGateway gateway;
  late FocusService focus;

  setUp(() {
    t = TestDb(start.toUtc());
    gateway = FakeNotificationGateway();
    focus = FocusService(
      db: t.db,
      scheduler: ReminderScheduler(
        db: t.db,
        gateway: gateway,
        now: () => t.now,
      ),
      now: () => t.now.toLocal(),
    );
  });
  tearDown(() => t.close());

  Iterable<({String title, String body, DateTime fireAt})> focusAlarms() =>
      gateway.scheduled.values
          .where((s) => s.payload!.startsWith('focusEnd:'))
          .map((s) => (title: s.title, body: s.body, fireAt: s.fireAt));

  test('start schedules the time-up notification with its buttons', () async {
    final task = await t.db.tasksDao.add(
      title: 'Essay',
      dueAt: DateTime(2026, 11, 20),
    );
    final s = await focus.start(taskId: task.id);
    final alarm = focusAlarms().single;
    expect(alarm.fireAt.toLocal(), DateTime(2026, 11, 14, 19, 10));
    expect(alarm.title, '10 minutes done');
    expect(alarm.body, contains('Essay'));
    final scheduled = gateway.scheduled.values.single;
    expect(scheduled.payload, 'focusEnd:${s.id}');
    expect(scheduled.actions.map((a) => a.label), ['Stop here', 'Keep going']);
  });

  test(
    'screen off for the whole ten minutes: stop records ten, completed',
    () async {
      await focus.start();
      t.now = start.add(const Duration(minutes: 23)).toUtc();
      final outcome = await focus.stop();
      expect(outcome, (minutes: 10, completed: true));
      final s = (await t.db.focusSessionsDao.recent()).single;
      expect(s.durationMinutes, 10);
      expect(s.completed, isTrue);
      expect(s.endedAt, t.now);
      expect(focusAlarms(), isEmpty);
    },
  );

  test(
    'stopping early records the minutes spent and cancels the alarm',
    () async {
      await focus.start();
      t.now = start.add(const Duration(minutes: 4, seconds: 10)).toUtc();
      expect(await focus.stop(), (minutes: 4, completed: false));
      expect(focusAlarms(), isEmpty);
      expect(await t.db.focusSessionsDao.getActive(), isNull);
      expect(await focus.stop(), isNull);
    },
  );

  test('keep going banks ten and starts ten more from now', () async {
    final task = await t.db.tasksDao.add(
      title: 'Essay',
      dueAt: DateTime(2026, 11, 20),
    );
    await focus.start(taskId: task.id);
    t.now = start.add(const Duration(minutes: 12)).toUtc();
    final next = await focus.keepGoing();

    expect(next!.taskId, task.id);
    expect(next.startedAt, t.now);
    final banked = (await t.db.focusSessionsDao.recent()).single;
    expect(banked.durationMinutes, 10);
    expect(banked.completed, isTrue);
    expect(
      focusAlarms().single.fireAt.toLocal(),
      DateTime(2026, 11, 14, 19, 22),
    );
  });

  test('starting again ends the live session first', () async {
    final first = await focus.start();
    t.now = start.add(const Duration(minutes: 2)).toUtc();
    final second = await focus.start();
    expect((await t.db.focusSessionsDao.getActive())?.id, second.id);
    final ended = await t.db.focusSessionsDao.getById(first.id);
    expect(ended!.durationMinutes, 2);
    expect(focusAlarms(), hasLength(1));
  });

  test(
    'notification buttons stop or keep going; stale ones do nothing',
    () async {
      final s = await focus.start();
      t.now = start.add(const Duration(minutes: 10)).toUtc();
      expect(
        await focus.handle(
          ReminderResponse(
            payload: 'focusEnd:${s.id}',
            actionId: ReminderActionIds.snooze,
          ),
        ),
        isTrue,
      );
      final next = await t.db.focusSessionsDao.getActive();
      expect(next!.id, isNot(s.id));

      // The old notification's Stop button no longer applies.
      await focus.handle(
        ReminderResponse(
          payload: 'focusEnd:${s.id}',
          actionId: ReminderActionIds.done,
        ),
      );
      expect((await t.db.focusSessionsDao.getActive())?.id, next.id);

      await focus.handle(
        ReminderResponse(
          payload: 'focusEnd:${next.id}',
          actionId: ReminderActionIds.done,
        ),
      );
      expect(await t.db.focusSessionsDao.getActive(), isNull);
      expect(
        await focus.handle(const ReminderResponse(payload: 'wake:1')),
        isFalse,
      );
      expect(
        (await t.db.focusSessionsDao.recent()).map((x) => x.durationMinutes),
        [0, 10],
      );
      expect(ReminderKind.focusEnd.name, 'focusEnd');
    },
  );
}
