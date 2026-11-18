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
    // Wake anchor: days without class still get a wake reminder, and the
    // weekend gets the hour of leeway.
    expect(firesFor('wake:3'), [DateTime(2026, 11, 18, 6, 30)]);
    expect(firesFor('leave:3'), isEmpty);
    expect(firesFor('wake:7'), [DateTime(2026, 11, 15, 7, 30)]);
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
    // Wake, eat, leave on Monday morning plus Monday evening's wind-down.
    expect(live.where((r) => r.ownerId == '1'), hasLength(4));
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

  test(
    'wind-down lands before a bedtime derived from tomorrow\'s wake',
    () async {
      await routine.resync();
      // Sunday night: Monday wake 06:30 - 8 h sleep = 22:30, minus 45 min.
      final sunday = gateway.scheduled.values.singleWhere(
        (s) => s.payload == 'windDown:7',
      );
      expect(sunday.fireAt.toLocal(), DateTime(2026, 11, 15, 21, 45));
      expect(sunday.body, contains('Bed around 22:30, up at 06:30'));
      expect(sunday.body, contains('Tomorrow: class 08:30, leave by 08:00.'));
      expect(sunday.actions.map((a) => a.label), ['Going to bed', 'Not today']);
      // Friday night: Saturday wake has the hour of leeway, so bed is later.
      expect(firesFor('windDown:5'), [DateTime(2026, 11, 20, 22, 45)]);
    },
  );

  test('"Going to bed" after midnight logs the night before', () async {
    t.now = DateTime(2026, 11, 17, 0, 40).toUtc();
    await routine.handle(
      const ReminderResponse(
        payload: 'windDown:1',
        actionId: ReminderActionIds.done,
      ),
    );
    final log = await t.db.dailyLogsDao.get(DateTime(2026, 11, 16));
    expect(log?.bedLoggedAt, t.now);
    expect(await t.db.dailyLogsDao.get(DateTime(2026, 11, 17)), isNull);
  });

  test('gradual shift moves wake reminders on schedule and settles', () async {
    await routine.startGradualWake(
      goalMinutes: 6 * 60,
      stepMinutes: 15,
      everyDays: 3,
    );
    await routine.resync();
    // Started Sat 14th at 06:30: Mon 16th still 06:30, Tue 17th 06:15.
    expect(firesFor('wake:1'), [DateTime(2026, 11, 16, 6, 30)]);
    expect(firesFor('wake:2'), [DateTime(2026, 11, 17, 6, 15)]);

    // Two weeks later, nothing logged in between: no reset, goal held.
    t.now = DateTime(2026, 11, 30, 5).toUtc();
    await routine.resync();
    expect(firesFor('wake:1'), [DateTime(2026, 11, 30, 6, 0)]);
    final s = await t.db.settingsDao.get();
    expect(s.targetWakeMinutes, 6 * 60);
    expect(s.wakeGoalMinutes, isNull);
  });

  test(
    'a later goal applies at once; setting the time stops a shift',
    () async {
      await routine.startGradualWake(goalMinutes: 7 * 60);
      expect((await t.db.settingsDao.get()).targetWakeMinutes, 7 * 60);
      expect((await t.db.settingsDao.get()).wakeGoalMinutes, isNull);

      await routine.startGradualWake(goalMinutes: 6 * 60);
      await routine.setWakeTime(6 * 60 + 45);
      final s = await t.db.settingsDao.get();
      expect(s.targetWakeMinutes, 6 * 60 + 45);
      expect(s.wakeGoalMinutes, isNull);
    },
  );

  test('low-energy mode keeps only wake and leave', () async {
    await t.db.settingsDao.setLowEnergy(true);
    await routine.resync();
    final kinds = gateway.scheduled.values
        .map((s) => s.payload!.split(':').first)
        .toSet();
    expect(kinds, {'wake', 'leave'});
  });
}
