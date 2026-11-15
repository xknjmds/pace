import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/db/app_database.dart';
import 'package:pace/core/notifications/reminder_actions.dart';
import 'package:pace/core/notifications/reminder_scheduler.dart';
import 'package:pace/features/routine/application/routine_reminders.dart';

import '../../../core/db/test_db.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  // Saturday 14 Nov 2026, 06:00 local; the test DB clock is UTC but the
  // planner only needs instants, so both agree on "now".
  final start = DateTime(2026, 11, 14, 6);
  late TestDb t;
  late FakeNotificationGateway gateway;
  late RoutineReminders routine;

  setUp(() async {
    t = TestDb(start.toUtc());
    gateway = FakeNotificationGateway();
    routine = RoutineReminders(
      db: t.db,
      scheduler: ReminderScheduler(
        db: t.db,
        gateway: gateway,
        now: () => t.now,
      ),
      now: () => t.now.toLocal(),
    );
    await t.db.weekdayScheduleDao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 8 * 60 + 30,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await t.db.weekdayScheduleDao.upsert(
      weekday: DateTime.tuesday,
      firstClassMinutes: 9 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
  });
  tearDown(() => t.close());

  Iterable<DateTime> firesFor(String payload) => gateway.scheduled.values
      .where((s) => s.payload == payload)
      .map((s) => s.fireAt.toLocal());

  test('resync schedules wake, eat and leave for each class day', () async {
    await routine.resync();
    expect(firesFor('wake:1'), [DateTime(2026, 11, 16, 6, 30)]);
    expect(firesFor('eat:1'), [DateTime(2026, 11, 16, 7, 15)]);
    expect(firesFor('leave:1'), [DateTime(2026, 11, 16, 8, 0)]);
    expect(firesFor('leave:2'), [DateTime(2026, 11, 17, 8, 30)]);
    expect(firesFor('wake:3'), isEmpty);
    final wake = gateway.scheduled.values.firstWhere(
      (s) => s.payload == 'wake:1',
    );
    expect(wake.actions.map((a) => a.id), [
      ReminderActionIds.done,
      ReminderActionIds.snooze,
      ReminderActionIds.notToday,
    ]);
  });

  test('changing a weekday reschedules that weekday', () async {
    await routine.resync();
    await t.db.weekdayScheduleDao.upsert(
      weekday: DateTime.monday,
      firstClassMinutes: 10 * 60,
      commuteMinutes: 30,
      prepMinutes: 30,
    );
    await routine.resync();
    expect(firesFor('leave:1'), [DateTime(2026, 11, 16, 9, 30)]);
    expect(firesFor('leave:2'), [DateTime(2026, 11, 17, 8, 30)]);
    final live = await t.db.scheduledNotificationsDao.getLive();
    expect(live.where((r) => r.ownerId == '1'), hasLength(3));
  });

  test('"Not today" mutes one reminder for the day and logs nothing', () async {
    // Monday morning, just after the wake reminder fired.
    t.now = DateTime(2026, 11, 16, 6, 31).toUtc();
    await routine.resync();
    expect(firesFor('eat:1'), [DateTime(2026, 11, 16, 7, 15)]);

    await routine.handle(
      const ReminderResponse(
        payload: 'eat:1',
        actionId: ReminderActionIds.notToday,
      ),
    );

    expect(firesFor('eat:1'), isEmpty);
    expect(firesFor('leave:1'), [DateTime(2026, 11, 16, 8, 0)]);
    expect(
      await t.db.reminderMutesDao.isMuted(
        ReminderKind.eat,
        '1',
        DateTime(2026, 11, 16),
      ),
      isTrue,
    );
    expect(await t.db.dailyLogsDao.get(DateTime(2026, 11, 16)), isNull);

    // Next Monday is planned again once it comes into the 7-day window.
    t.now = DateTime(2026, 11, 17, 6).toUtc();
    await routine.resync();
    expect(firesFor('eat:1'), [DateTime(2026, 11, 23, 7, 15)]);
  });

  test('snooze adds one copy without a snooze button', () async {
    t.now = DateTime(2026, 11, 16, 6, 31).toUtc();
    await routine.resync();
    await routine.handle(
      const ReminderResponse(
        payload: 'wake:1',
        actionId: ReminderActionIds.snooze,
      ),
    );
    final snoozed = gateway.scheduled.values.singleWhere(
      (s) => s.payload == 'wake:1:snooze',
    );
    expect(snoozed.fireAt.toLocal(), DateTime(2026, 11, 16, 6, 41));
    expect(
      snoozed.actions.map((a) => a.id),
      isNot(contains(ReminderActionIds.snooze)),
    );

    // Snoozing the snooze is not offered, and handling it does not stack.
    await routine.handle(
      const ReminderResponse(
        payload: 'wake:1:snooze',
        actionId: ReminderActionIds.done,
      ),
    );
    expect(firesFor('wake:1:snooze'), isEmpty);
    final log = await t.db.dailyLogsDao.get(DateTime(2026, 11, 16));
    expect(log?.wakeLoggedAt, t.now);
  });

  test('done logs the step for today', () async {
    t.now = DateTime(2026, 11, 16, 8, 2).toUtc();
    await routine.handle(
      const ReminderResponse(
        payload: 'leave:1',
        actionId: ReminderActionIds.done,
      ),
    );
    final log = await t.db.dailyLogsDao.get(DateTime(2026, 11, 16));
    expect(log?.routineDone, isTrue);
  });

  test('responses for other kinds or plain taps are left alone', () async {
    expect(
      await routine.handle(const ReminderResponse(payload: 'deadline:abc')),
      isFalse,
    );
    expect(
      await routine.handle(const ReminderResponse(payload: 'garbage')),
      isFalse,
    );
    expect(
      await routine.handle(const ReminderResponse(payload: 'wake:1')),
      isTrue,
    );
    expect(await t.db.dailyLogsDao.get(DateTime(2026, 11, 14)), isNull);
  });
}
