import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/routine/domain/morning_plan.dart';

void main() {
  MorningInputs inputs({
    LocalTime? firstClass,
    int commute = 30,
    int prep = 30,
    int breakfast = 15,
    LocalTime? targetWake,
  }) => MorningInputs(
    firstClass: firstClass,
    commuteMinutes: commute,
    prepMinutes: prep,
    breakfastMinutes: breakfast,
    targetWake: targetWake ?? LocalTime.of(6, 30),
  );

  group('computeLeaveByPlan', () {
    test('normal day keeps the target wake and lays out the morning', () {
      final plan =
          computeLeaveByPlan(inputs(firstClass: LocalTime.of(8, 30)))
              as LeaveByPlan;
      expect(plan.leave, LocalTime.of(8, 0));
      expect(plan.eatEnd, LocalTime.of(7, 30));
      expect(plan.eatStart, LocalTime.of(7, 15));
      expect(plan.wake, LocalTime.of(6, 30));
      expect(plan.wakeTooLate, isFalse);
      expect(plan.slackMinutes, 45);
    });

    test('no class day', () {
      expect(computeLeaveByPlan(inputs()), isA<NoClassMorning>());
    });

    test('target wake too late: wake moves to the latest workable time', () {
      final plan =
          computeLeaveByPlan(
                inputs(
                  firstClass: LocalTime.of(7, 0),
                  commute: 45,
                  targetWake: LocalTime.of(6, 30),
                ),
              )
              as LeaveByPlan;
      expect(plan.leave, LocalTime.of(6, 15));
      expect(plan.wake, LocalTime.of(5, 30));
      expect(plan.eatStart, LocalTime.of(5, 30));
      expect(plan.wakeTooLate, isTrue);
      expect(plan.slackMinutes, 0);
    });

    test('impossible schedule: the morning does not fit before the class', () {
      final plan = computeLeaveByPlan(
        inputs(firstClass: LocalTime.of(1, 0), commute: 60),
      );
      expect(plan, isA<ImpossibleMorning>());
      expect((plan as ImpossibleMorning).neededMinutes, 105);
    });
  });

  group('computeLatePlan', () {
    test('still time to get ready: leave at the planned time, on time', () {
      final late = computeLatePlan(
        now: LocalTime.of(7, 20),
        firstClass: LocalTime.of(8, 30),
        commuteMinutes: 30,
        prepMinutes: 30,
      );
      expect(late.action, LateAction.getReady);
      expect(late.leaveAt, LocalTime.of(8, 0));
      expect(late.arriveAt, LocalTime.of(8, 30));
      expect(late.onTime, isTrue);
    });

    test('prep no longer fits but leaving now still arrives on time', () {
      final late = computeLatePlan(
        now: LocalTime.of(7, 45),
        firstClass: LocalTime.of(8, 30),
        commuteMinutes: 30,
        prepMinutes: 30,
      );
      expect(late.action, LateAction.leaveNow);
      expect(late.leaveAt, LocalTime.of(7, 45));
      expect(late.arriveAt, LocalTime.of(8, 15));
      expect(late.minutesLate, 0);
    });

    test('properly late: leave now, arrive after the class starts', () {
      final late = computeLatePlan(
        now: LocalTime.of(8, 15),
        firstClass: LocalTime.of(8, 30),
        commuteMinutes: 30,
        prepMinutes: 30,
      );
      expect(late.action, LateAction.leaveNow);
      expect(late.arriveAt, LocalTime.of(8, 45));
      expect(late.minutesLate, 15);
      expect(late.onTime, isFalse);
    });
  });
}
