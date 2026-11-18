import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/routine/domain/morning_plan.dart';
import 'package:pace/features/routine/domain/routine_reminder_planner.dart';
import 'package:pace/features/routine/domain/wake_schedule.dart';
import 'package:pace/features/today/domain/today_model.dart';

void main() {
  final classDay = MorningInputs(
    firstClass: LocalTime.of(8, 30),
    commuteMinutes: 30,
    prepMinutes: 30,
    breakfastMinutes: 15,
    targetWake: LocalTime.of(6, 30),
  );
  final freeDay = MorningInputs(
    firstClass: null,
    commuteMinutes: 30,
    prepMinutes: 30,
    breakfastMinutes: 15,
    targetWake: LocalTime.of(6, 30),
  );

  RoutineStatus status({
    required DateTime now,
    MorningInputs? inputs,
    bool wake = false,
    bool eat = false,
    bool leave = false,
    bool lowEnergy = false,
  }) => routineStatus(
    now: now,
    inputs: inputs ?? classDay,
    wakeDone: wake,
    eatDone: eat,
    leaveDone: leave,
    lateThresholdMinutes: 20,
    lowEnergy: lowEnergy,
  );

  test('before wake: next step is up, all three listed', () {
    final s = status(now: DateTime(2026, 11, 16, 6)) as StepsRemaining;
    expect(s.next.step, RoutineStep.wake);
    expect(s.steps.map((x) => x.label), ['Up', 'Eat', 'Leave']);
    expect(s.steps.map((x) => x.at.format24()), ['06:30', '07:15', '08:00']);
  });

  test('within the threshold it is still just the next step', () {
    final s = status(now: DateTime(2026, 11, 16, 6, 50));
    expect(s, isA<StepsRemaining>());
  });

  test('past wake plus threshold and not up: the late card', () {
    final s = status(now: DateTime(2026, 11, 16, 7, 50)) as RunningLate;
    expect(s.plan.action, LateAction.leaveNow);
    expect(s.title, 'Leave now');
    expect(s.subtitle, 'You still arrive on time, 08:20.');

    final later = status(now: DateTime(2026, 11, 16, 8, 15)) as RunningLate;
    expect(later.subtitle, 'You arrive about 08:45.');
    expect(later.subtitle, isNot(contains('late')));
  });

  test('late but prep still fits: get ready by the planned leave time', () {
    final s = status(now: DateTime(2026, 11, 16, 7, 0)) as RunningLate;
    expect(s.plan.action, LateAction.getReady);
    expect(s.title, 'Get ready, leave by 08:00');
  });

  test('up on time, late for nothing: eat is next', () {
    final s =
        status(now: DateTime(2026, 11, 16, 7, 50), wake: true)
            as StepsRemaining;
    expect(s.next.step, RoutineStep.eat);
  });

  test('an hour into class the late card gives way to the list', () {
    expect(status(now: DateTime(2026, 11, 16, 9, 45)), isA<StepsRemaining>());
  });

  test('all done, no class, impossible', () {
    expect(
      status(
        now: DateTime(2026, 11, 16, 9),
        wake: true,
        eat: true,
        leave: true,
      ),
      isA<RoutineAllDone>(),
    );
    expect(
      status(now: DateTime(2026, 11, 16, 9), inputs: freeDay),
      isA<NoClassToday>(),
    );
    expect(
      status(
        now: DateTime(2026, 11, 16, 9),
        inputs: MorningInputs(
          firstClass: LocalTime.of(0, 30),
          commuteMinutes: 60,
          prepMinutes: 30,
          breakfastMinutes: 15,
          targetWake: LocalTime.of(6, 30),
        ),
      ),
      isA<MorningDoesNotFit>(),
    );
  });

  test('low-energy mode drops the eat step', () {
    final s =
        status(now: DateTime(2026, 11, 16, 6), lowEnergy: true)
            as StepsRemaining;
    expect(s.steps.map((x) => x.step), [RoutineStep.wake, RoutineStep.leave]);
    expect(
      status(
        now: DateTime(2026, 11, 16, 9),
        wake: true,
        leave: true,
        lowEnergy: true,
      ),
      isA<RoutineAllDone>(),
    );
  });

  test('tomorrow preview is one line, or nothing without a class', () {
    expect(tomorrowPreview(classDay), 'Tomorrow: class 08:30, leave by 08:00');
    expect(tomorrowPreview(freeDay), isNull);
  });

  test('no class with the wake anchor offers "I\'m up"', () {
    final s =
        routineStatus(
              now: DateTime(2026, 11, 15, 7),
              inputs: freeDay,
              wakeDone: false,
              eatDone: false,
              leaveDone: false,
              lateThresholdMinutes: 20,
              lowEnergy: false,
              wakeAnchor: true,
            )
            as NoClassToday;
    expect(s.wake!.at, LocalTime.of(6, 30));
    expect(
      (status(now: DateTime(2026, 11, 15, 7), inputs: freeDay) as NoClassToday)
          .wake,
      isNull,
    );
  });

  group('showEveningCard', () {
    final night = nightPlan(
      plan: const WakePlan(baseWakeMinutes: 390),
      night: DateTime(2026, 11, 16),
      sleepTargetMinutes: 480,
      windDownLeadMinutes: 45,
    );
    bool show(DateTime now, {bool bed = false}) =>
        showEveningCard(now: now, night: night, bedLogged: bed);

    test('from wind-down until four hours past bedtime', () {
      expect(show(DateTime(2026, 11, 16, 21, 44)), isFalse);
      expect(show(DateTime(2026, 11, 16, 21, 45)), isTrue);
      expect(show(DateTime(2026, 11, 17, 1, 0)), isTrue);
      expect(show(DateTime(2026, 11, 17, 2, 30)), isFalse);
      expect(show(DateTime(2026, 11, 17, 6, 0)), isFalse);
    });

    test('gone once bed is logged', () {
      expect(show(DateTime(2026, 11, 16, 22), bed: true), isFalse);
    });
  });
}
