import 'package:flutter_test/flutter_test.dart';
import 'package:pace/core/mascot/tuck_pose.dart';
import 'package:pace/core/time/local_time.dart';
import 'package:pace/features/routine/domain/morning_plan.dart';
import 'package:pace/features/routine/domain/routine_reminder_planner.dart';
import 'package:pace/features/today/domain/today_model.dart';
import 'package:pace/features/today/domain/tuck_pose_for.dart';

RoutineStepItem step(RoutineStep s, {bool done = false}) =>
    RoutineStepItem(step: s, at: LocalTime.of(7, 0), done: done);

StepsRemaining nextIs(RoutineStep s) {
  final steps = [
    step(RoutineStep.wake, done: s != RoutineStep.wake),
    step(RoutineStep.eat, done: s == RoutineStep.leave),
    step(RoutineStep.leave),
  ];
  return StepsRemaining(
    steps: steps,
    next: steps.firstWhere((x) => x.step == s),
  );
}

void main() {
  final morning = DateTime(2026, 11, 18, 7, 30);

  TuckPose pose({
    DateTime? now,
    RoutineStatus? status,
    bool evening = false,
    bool lowEnergy = false,
    bool focus = false,
  }) => tuckPoseFor(
    now: now ?? morning,
    status: status,
    evening: evening,
    lowEnergy: lowEnergy,
    focusRunning: focus,
  );

  test('low-energy mode always rests, whatever else is going on', () {
    expect(
      pose(
        lowEnergy: true,
        evening: true,
        focus: true,
        status: nextIs(RoutineStep.leave),
      ),
      TuckPose.resting,
    );
  });

  test('evening and late night wind down', () {
    expect(pose(evening: true), TuckPose.evening);
    expect(pose(now: DateTime(2026, 11, 18, 23, 10)), TuckPose.evening);
    expect(pose(now: DateTime(2026, 11, 19, 3, 0)), TuckPose.evening);
  });

  test('a running focus timer reads', () {
    expect(pose(focus: true, status: nextIs(RoutineStep.wake)), TuckPose.focus);
  });

  test('the next routine step picks the pose', () {
    expect(pose(status: nextIs(RoutineStep.wake)), TuckPose.morning);
    expect(pose(status: nextIs(RoutineStep.eat)), TuckPose.morning);
    expect(pose(status: nextIs(RoutineStep.leave)), TuckPose.leaving);
  });

  test('running late just means walking, never worry', () {
    final late = RunningLate(
      plan: LatePlan(
        action: LateAction.leaveNow,
        leaveAt: LocalTime.of(7, 40),
        arriveAt: LocalTime.of(8, 5),
        minutesLate: 5,
      ),
      steps: [step(RoutineStep.wake), step(RoutineStep.leave)],
    );
    expect(pose(status: late), TuckPose.leaving);
  });

  test('routine done is quietly proud', () {
    expect(pose(status: const RoutineAllDone()), TuckPose.proud);
  });

  test('no class: morning until up, then idle', () {
    expect(
      pose(status: NoClassToday(wake: step(RoutineStep.wake))),
      TuckPose.morning,
    );
    expect(
      pose(status: NoClassToday(wake: step(RoutineStep.wake, done: true))),
      TuckPose.idle,
    );
    expect(pose(status: const NoClassToday()), TuckPose.idle);
  });

  test('nothing to go on is idle', () {
    expect(pose(), TuckPose.idle);
    expect(pose(status: const MorningDoesNotFit()), TuckPose.idle);
  });
}
