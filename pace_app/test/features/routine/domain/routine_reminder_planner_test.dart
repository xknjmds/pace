import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/routine/domain/morning_plan.dart';
import 'package:pace/features/routine/domain/routine_reminder_planner.dart';
import 'package:pace/features/routine/domain/wake_schedule.dart';

void main() {
  // Saturday 14 Nov 2026, 06:00 local.
  final now = DateTime(2026, 11, 14, 6);
  final monday = MorningInputs(
    firstClass: LocalTime.of(8, 30),
    commuteMinutes: 30,
    prepMinutes: 30,
    breakfastMinutes: 15,
    targetWake: LocalTime.of(6, 30),
  );

  test('one wake, eat and leave per scheduled day in the next week', () {
    final planned = planRoutineReminders(
      now: now,
      inputsByWeekday: {DateTime.monday: monday, DateTime.wednesday: monday},
      muted: {},
    );
    expect(planned, hasLength(6));
    final mon = planned.where((p) => p.weekday == DateTime.monday).toList();
    expect(mon.map((p) => p.step), [
      RoutineStep.wake,
      RoutineStep.eat,
      RoutineStep.leave,
    ]);
    expect(mon[0].draft.fireAt, DateTime(2026, 11, 16, 6, 30));
    expect(mon[1].draft.fireAt, DateTime(2026, 11, 16, 7, 15));
    expect(mon[2].draft.fireAt, DateTime(2026, 11, 16, 8, 0));
    expect(mon[2].draft.body, contains('Class at 08:30'));
  });

  test('times already past today are skipped, next week is not planned', () {
    final sat = MorningInputs(
      firstClass: LocalTime.of(7, 0),
      commuteMinutes: 20,
      prepMinutes: 20,
      breakfastMinutes: 10,
      targetWake: LocalTime.of(6, 30),
    );
    final planned = planRoutineReminders(
      now: DateTime(2026, 11, 14, 6, 15),
      inputsByWeekday: {DateTime.saturday: sat},
      muted: {},
    );
    // Wake 06:10 is past; eat 06:10 merged into wake anyway; leave 06:40 stays.
    expect(planned.map((p) => p.step), [RoutineStep.leave]);
    expect(planned.single.draft.fireAt, DateTime(2026, 11, 14, 6, 40));
  });

  test('no slack folds breakfast into the wake reminder', () {
    final tight = MorningInputs(
      firstClass: LocalTime.of(7, 0),
      commuteMinutes: 45,
      prepMinutes: 30,
      breakfastMinutes: 15,
      targetWake: LocalTime.of(6, 30),
    );
    final planned = planRoutineReminders(
      now: now,
      inputsByWeekday: {DateTime.monday: tight},
      muted: {},
    );
    expect(planned.map((p) => p.step), [RoutineStep.wake, RoutineStep.leave]);
    expect(planned.first.draft.body, contains('Breakfast first.'));
    expect(planned.first.draft.body, contains('earlier than usual'));
  });

  test('"Not today" mutes one step on one date only', () {
    final planned = planRoutineReminders(
      now: now,
      inputsByWeekday: {DateTime.monday: monday},
      muted: {'wake:1:2026-11-16'},
    );
    expect(planned.map((p) => p.step), [RoutineStep.eat, RoutineStep.leave]);
  });

  test('days without a row or without a class produce nothing', () {
    final free = MorningInputs(
      firstClass: null,
      commuteMinutes: 30,
      prepMinutes: 30,
      breakfastMinutes: 15,
      targetWake: LocalTime.of(6, 30),
    );
    expect(
      planRoutineReminders(
        now: now,
        inputsByWeekday: {DateTime.sunday: free},
        muted: {},
      ),
      isEmpty,
    );
  });

  group('wake anchor, wind-down and low energy', () {
    const plan = WakePlan(baseWakeMinutes: 390);
    final windDown = const WindDownSettings(
      wakePlan: plan,
      sleepTargetMinutes: 480,
      leadMinutes: 45,
    );

    test('days without class get a wake reminder when anchored', () {
      final planned = planRoutineReminders(
        now: now,
        inputsByWeekday: {DateTime.monday: monday},
        muted: {},
        wakeFor: (d) => wakeOn(plan, d),
        wakeAnchor: true,
      );
      final wakes = planned.where((p) => p.step == RoutineStep.wake);
      expect(wakes, hasLength(7));
      final sunday = wakes.firstWhere((p) => p.weekday == DateTime.sunday);
      expect(sunday.draft.fireAt, DateTime(2026, 11, 15, 7, 30));
      expect(sunday.draft.body, contains('No class today'));
      expect(planned.where((p) => p.step == RoutineStep.leave), hasLength(1));
    });

    test('one wind-down per evening, before the derived bedtime', () {
      final planned = planRoutineReminders(
        now: now,
        inputsByWeekday: {DateTime.monday: monday},
        muted: {},
        wakeFor: (d) => wakeOn(plan, d),
        windDown: windDown,
      );
      final evenings = planned.where((p) => p.step == RoutineStep.windDown);
      expect(evenings, hasLength(7));
      final sunday = evenings.firstWhere((p) => p.weekday == DateTime.sunday);
      expect(sunday.draft.fireAt, DateTime(2026, 11, 15, 21, 45));
    });

    test('low-energy mode keeps only wake and leave', () {
      final planned = planRoutineReminders(
        now: now,
        inputsByWeekday: {DateTime.monday: monday},
        muted: {},
        wakeFor: (d) => wakeOn(plan, d),
        wakeAnchor: true,
        windDown: windDown,
        lowEnergy: true,
      );
      expect(planned.map((p) => p.step).toSet(), {
        RoutineStep.wake,
        RoutineStep.leave,
      });
      final mon = planned.firstWhere(
        (p) => p.weekday == DateTime.monday && p.step == RoutineStep.wake,
      );
      expect(mon.draft.body, isNot(contains('Breakfast')));
    });

    test('a muted wind-down skips that evening only', () {
      final planned = planRoutineReminders(
        now: now,
        inputsByWeekday: {DateTime.monday: monday},
        muted: {'windDown:6:2026-11-14'},
        wakeFor: (d) => wakeOn(plan, d),
        windDown: windDown,
      );
      final evenings = planned.where((p) => p.step == RoutineStep.windDown);
      expect(
        evenings.map((p) => p.weekday),
        isNot(contains(DateTime.saturday)),
      );
      expect(evenings, hasLength(6));
    });
  });
}
