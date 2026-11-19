import '../../../core/time/local_time.dart';
import '../../routine/domain/morning_plan.dart';
import '../../routine/domain/routine_reminder_planner.dart';
import '../../routine/domain/wake_schedule.dart';

/// One routine step as Today shows it.
class RoutineStepItem {
  const RoutineStepItem({
    required this.step,
    required this.at,
    required this.done,
    this.skipped = false,
  });

  final RoutineStep step;
  final LocalTime at;

  /// Settled for today: logged, or [skipped].
  final bool done;

  /// The owner said it didn't happen today. Settled, shown as "Not today".
  final bool skipped;

  String get label => switch (step) {
    RoutineStep.wake => 'Up',
    RoutineStep.eat => 'Eat',
    RoutineStep.leave => 'Leave',
    RoutineStep.windDown => 'Wind down',
  };
}

sealed class RoutineStatus {
  const RoutineStatus();
}

/// No class. With the wake anchor on, [wake] is the steady wake time to
/// log with "I'm up".
class NoClassToday extends RoutineStatus {
  const NoClassToday({this.wake});

  final RoutineStepItem? wake;
}

class MorningDoesNotFit extends RoutineStatus {
  const MorningDoesNotFit();
}

/// The usual case: steps in order, [next] is the first one not done.
class StepsRemaining extends RoutineStatus {
  const StepsRemaining({required this.steps, required this.next});

  final List<RoutineStepItem> steps;
  final RoutineStepItem next;
}

/// Past the planned wake by more than the threshold and not up yet:
/// one card, one action, an arrival time. No red, no "late".
class RunningLate extends RoutineStatus {
  const RunningLate({required this.plan, required this.steps});

  final LatePlan plan;
  final List<RoutineStepItem> steps;

  String get title => switch (plan.action) {
    LateAction.getReady => 'Get ready, leave by ${plan.leaveAt.format24()}',
    LateAction.leaveNow => 'Leave now',
  };

  String get subtitle => plan.onTime
      ? 'You still arrive on time, ${plan.arriveAt.format24()}.'
      : 'You arrive about ${plan.arriveAt.format24()}.';
}

/// Every step settled. [steps] stay on the card so a check-in can still
/// be changed.
class RoutineAllDone extends RoutineStatus {
  const RoutineAllDone({this.steps = const []});

  final List<RoutineStepItem> steps;
}

/// Pure: what Today says about the morning routine right now.
///
/// After the first class has been under way for an hour the late card
/// stops making sense, so the plain step list returns.
///
/// Steps in [skipped] ("didn't happen today") count as settled, so the
/// card moves on to the next one.
RoutineStatus routineStatus({
  required DateTime now,
  required MorningInputs inputs,
  required bool wakeDone,
  required bool eatDone,
  required bool leaveDone,
  required int lateThresholdMinutes,
  required bool lowEnergy,
  bool wakeAnchor = false,
  Set<RoutineStep> skipped = const {},
}) {
  RoutineStepItem item(RoutineStep step, LocalTime at, bool logged) =>
      RoutineStepItem(
        step: step,
        at: at,
        done: logged || skipped.contains(step),
        skipped: !logged && skipped.contains(step),
      );
  final plan = computeLeaveByPlan(inputs);
  switch (plan) {
    case NoClassMorning():
      return NoClassToday(
        wake: wakeAnchor
            ? item(RoutineStep.wake, inputs.targetWake, wakeDone)
            : null,
      );
    case ImpossibleMorning():
      return const MorningDoesNotFit();
    case LeaveByPlan():
      break;
  }

  final steps = [
    item(RoutineStep.wake, plan.wake, wakeDone),
    if (!lowEnergy) item(RoutineStep.eat, plan.eatStart, eatDone),
    item(RoutineStep.leave, plan.leave, leaveDone),
  ];
  final remaining = steps.where((s) => !s.done);
  if (remaining.isEmpty) return RoutineAllDone(steps: steps);

  final nowM = now.hour * 60 + now.minute;
  final wakeDeadline = plan.wake.minutesSinceMidnight + lateThresholdMinutes;
  final classOver = plan.firstClass.minutesSinceMidnight + 60;
  if (!steps.first.done && nowM > wakeDeadline && nowM < classOver) {
    return RunningLate(
      plan: computeLatePlan(
        now: LocalTime(nowM),
        firstClass: plan.firstClass,
        commuteMinutes: inputs.commuteMinutes,
        prepMinutes: inputs.prepMinutes,
      ),
      steps: steps,
    );
  }
  return StepsRemaining(steps: steps, next: remaining.first);
}

/// Pure: the one-line look ahead, or null when tomorrow has no class.
String? tomorrowPreview(MorningInputs tomorrow) {
  final plan = computeLeaveByPlan(tomorrow);
  return switch (plan) {
    LeaveByPlan p =>
      'Tomorrow: class ${p.firstClass.format24()}, '
          'leave by ${p.leave.format24()}',
    _ => null,
  };
}

/// Pure: whether Today shows the evening card for [night]. From wind-down
/// until four hours past bedtime, unless bed has been logged.
bool showEveningCard({
  required DateTime now,
  required NightPlan night,
  required bool bedLogged,
}) =>
    !bedLogged &&
    !now.isBefore(night.windDownAt) &&
    now.isBefore(night.bedtime.add(const Duration(hours: 4)));

/// Pure: a gentle greeting for the time of day.
String greetingFor(DateTime now) => switch (now.hour) {
  >= 5 && < 12 => 'Good morning',
  >= 12 && < 18 => 'Good afternoon',
  _ => 'Good evening',
};

const _longWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _longMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Pure: "Monday, 16 November".
String longDate(DateTime d) =>
    '${_longWeekdays[d.weekday - 1]}, ${d.day} ${_longMonths[d.month - 1]}';
