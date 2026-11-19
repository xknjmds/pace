import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/notifications/reminder_scheduler.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/onboarding/application/setup_service.dart';
import 'package:pace/features/onboarding/domain/setup_plan.dart';
import 'package:pace/features/routine/application/routine_reminders.dart';

import '../../../core/db/test_db.dart';
import '../../../core/notifications/fake_notification_gateway.dart';

void main() {
  // Monday 16 Nov 2026, 20:00 local.
  final start = DateTime(2026, 11, 16, 20);
  late TestDb t;
  late SetupService service;
  var resyncs = 0;

  setUp(() {
    t = TestDb(start.toUtc());
    resyncs = 0;
    final scheduler = ReminderScheduler(
      db: t.db,
      gateway: FakeNotificationGateway(),
      now: () => t.now,
    );
    service = SetupService(
      db: t.db,
      routine: RoutineReminders(
        db: t.db,
        scheduler: scheduler,
        now: () => t.now.toLocal(),
      ),
      resync: () async => resyncs++,
      now: () => t.now.toLocal(),
    );
  });
  tearDown(() => t.close());

  SetupPlan plan(LocalTime usualWake, {Chronotype c = Chronotype.inBetween}) =>
      planFromAnswers(
        SetupAnswers(
          classDays: const {1, 2, 3, 4, 5},
          firstClass: LocalTime.of(8, 0),
          commuteMinutes: 25,
          prepMinutes: 35,
          usualWake: usualWake,
          sleepTargetMinutes: 450,
          chronotype: c,
        ),
      );

  test('apply writes the week, sleep, wake and marks setup done', () async {
    await service.apply(plan(LocalTime.of(6, 0)));

    final days = await t.db.weekdayScheduleDao.getAll();
    expect(days, hasLength(7));
    final monday = days.firstWhere((d) => d.weekday == DateTime.monday);
    expect(monday.firstClassMinutes, 8 * 60);
    expect(monday.commuteMinutes, 25);
    expect(monday.prepMinutes, 35);
    final saturday = days.firstWhere((d) => d.weekday == DateTime.saturday);
    expect(saturday.firstClassMinutes, isNull);

    final s = await t.db.settingsDao.get();
    expect(s.targetWakeMinutes, 6 * 60);
    expect(s.wakeGoalMinutes, isNull);
    expect(s.sleepTargetMinutes, 450);
    expect(s.weekendLeewayMinutes, 45);
    expect(s.onboardedAt, isNotNull);
    expect(resyncs, 1);
  });

  test('a much later usual wake starts the gradual shift', () async {
    await service.apply(plan(LocalTime.of(8, 0), c: Chronotype.night));
    final s = await t.db.settingsDao.get();
    expect(s.targetWakeMinutes, 8 * 60);
    expect(s.wakeShiftFromMinutes, 8 * 60);
    expect(s.wakeGoalMinutes, 6 * 60 + 30);
    expect(s.wakeShiftStepMinutes, 10);
    expect(s.wakeShiftEveryDays, 4);
  });

  test('skip only marks setup done', () async {
    await service.skip();
    final s = await t.db.settingsDao.get();
    expect(s.onboardedAt, isNotNull);
    expect(await t.db.weekdayScheduleDao.getAll(), isEmpty);
    expect(resyncs, 0);
  });
}
