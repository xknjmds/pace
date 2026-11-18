import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/routine/domain/wake_schedule.dart';

void main() {
  final start = DateTime(2026, 11, 14); // Saturday
  WakeShift shift({
    int from = 450,
    int goal = 390,
    int step = 15,
    int every = 3,
  }) => WakeShift(
    fromMinutes: from,
    goalMinutes: goal,
    startDate: start,
    stepMinutes: step,
    everyDays: every,
  );
  DateTime day(int offset) => DateTime(2026, 11, 14 + offset);

  group('gradualWakeMinutes', () {
    test('holds for the first block of days, then steps earlier', () {
      final s = shift();
      expect(
        [for (var i = 0; i < 10; i++) gradualWakeMinutes(s, day(i))],
        [450, 450, 450, 435, 435, 435, 420, 420, 420, 405],
      );
    });

    test('reaches the goal and stays there', () {
      final s = shift();
      expect(gradualWakeMinutes(s, day(12)), 390);
      expect(gradualWakeMinutes(s, day(13)), 390);
      expect(gradualWakeMinutes(s, day(200)), 390);
    });

    test('never overshoots when the step does not divide the gap', () {
      final s = shift(from: 480, goal: 400, step: 30, every: 2);
      expect(
        [for (var i = 0; i < 10; i += 2) gradualWakeMinutes(s, day(i))],
        [480, 450, 420, 400, 400],
      );
    });

    test('a missed night changes nothing: only the calendar counts', () {
      // There is no log input at all; day 7 is day 7 whatever happened.
      expect(gradualWakeMinutes(shift(), day(7)), 420);
    });

    test('dates before the start and a goal not earlier', () {
      expect(gradualWakeMinutes(shift(), day(-3)), 450);
      expect(gradualWakeMinutes(shift(from: 400, goal: 420), day(1)), 420);
    });

    test('counts calendar days across the DST change', () {
      final s = WakeShift(
        fromMinutes: 450,
        goalMinutes: 390,
        startDate: DateTime(2026, 10, 24),
        everyDays: 3,
      );
      // 24 Oct to 3 Nov is 10 calendar days in any time zone.
      expect(gradualWakeMinutes(s, DateTime(2026, 11, 3, 6)), 405);
    });
  });

  test('shiftReachesGoalOn matches the first goal day', () {
    final s = shift();
    final reached = shiftReachesGoalOn(s);
    expect(reached, day(12));
    expect(gradualWakeMinutes(s, reached), 390);
    expect(gradualWakeMinutes(s, day(11)), greaterThan(390));
  });

  group('wakeOn', () {
    const plan = WakePlan(baseWakeMinutes: 390, weekendLeewayMinutes: 60);
    test('weekdays use the weekday time, weekends add the leeway', () {
      expect(wakeOn(plan, DateTime(2026, 11, 16)), LocalTime.of(6, 30));
      expect(wakeOn(plan, DateTime(2026, 11, 14)), LocalTime.of(7, 30));
      expect(wakeOn(plan, DateTime(2026, 11, 15)), LocalTime.of(7, 30));
    });

    test('weekend stays within an hour even if set higher', () {
      const loose = WakePlan(baseWakeMinutes: 390, weekendLeewayMinutes: 180);
      expect(wakeOn(loose, DateTime(2026, 11, 14)), LocalTime.of(7, 30));
    });

    test('the weekend follows the shift', () {
      final shifting = WakePlan(
        baseWakeMinutes: 450,
        weekendLeewayMinutes: 30,
        shift: shift(),
      );
      // Saturday 21st is day 7: weekday 07:00, weekend 07:30.
      expect(wakeOn(shifting, day(7)), LocalTime.of(7, 30));
      expect(weekdayWakeOn(shifting, day(7)), LocalTime.of(7, 0));
    });
  });

  test('nightOf: before noon belongs to the night before', () {
    expect(nightOf(DateTime(2026, 11, 17, 0, 40)), DateTime(2026, 11, 16));
    expect(nightOf(DateTime(2026, 11, 16, 22, 30)), DateTime(2026, 11, 16));
    expect(nightOf(DateTime(2026, 11, 17, 11, 59)), DateTime(2026, 11, 16));
  });

  test('bedtime is derived from tomorrow\'s wake and the sleep target', () {
    const plan = WakePlan(baseWakeMinutes: 390);
    final n = nightPlan(
      plan: plan,
      night: DateTime(2026, 11, 16),
      sleepTargetMinutes: 480,
      windDownLeadMinutes: 45,
    );
    expect(n.wakeAt, DateTime(2026, 11, 17, 6, 30));
    expect(n.bedtime, DateTime(2026, 11, 16, 22, 30));
    expect(n.windDownAt, DateTime(2026, 11, 16, 21, 45));

    final friday = nightPlan(
      plan: plan,
      night: DateTime(2026, 11, 20),
      sleepTargetMinutes: 480,
      windDownLeadMinutes: 45,
    );
    expect(friday.bedtime, DateTime(2026, 11, 20, 23, 30));
  });
}
