import '../../../core/time/local_time.dart';

/// Everything a morning's plan depends on. Minutes are durations.
class MorningInputs {
  const MorningInputs({
    required this.firstClass,
    required this.commuteMinutes,
    required this.prepMinutes,
    required this.breakfastMinutes,
    required this.targetWake,
  });

  /// Null means no class that day.
  final LocalTime? firstClass;
  final int commuteMinutes;
  final int prepMinutes;
  final int breakfastMinutes;
  final LocalTime targetWake;
}

/// Result of [computeLeaveByPlan].
sealed class MorningPlan {
  const MorningPlan();
}

/// No class: nothing to leave for. Wake anchor still applies (M9).
class NoClassMorning extends MorningPlan {
  const NoClassMorning();
}

/// Commute, prep and breakfast do not fit between midnight and the class.
class ImpossibleMorning extends MorningPlan {
  const ImpossibleMorning({
    required this.firstClass,
    required this.neededMinutes,
  });

  final LocalTime firstClass;
  final int neededMinutes;
}

/// The morning laid out backwards from the first class:
/// wake, free time, breakfast, getting ready, leave.
class LeaveByPlan extends MorningPlan {
  const LeaveByPlan({
    required this.firstClass,
    required this.wake,
    required this.eatStart,
    required this.eatEnd,
    required this.leave,
    required this.wakeTooLate,
    required this.slackMinutes,
  });

  final LocalTime firstClass;

  /// The target wake time, or the latest workable one when
  /// [wakeTooLate] is set.
  final LocalTime wake;
  final LocalTime eatStart;
  final LocalTime eatEnd;
  final LocalTime leave;

  /// The owner's target wake time is later than the morning allows.
  final bool wakeTooLate;

  /// Free minutes between waking and breakfast.
  final int slackMinutes;
}

/// Pure: lays the morning out from the first class backwards. The owner's
/// target wake time is kept whenever it is early enough, because a steady
/// wake time is the point of the routine.
MorningPlan computeLeaveByPlan(MorningInputs i) {
  final firstClass = i.firstClass;
  if (firstClass == null) return const NoClassMorning();

  final needed = i.commuteMinutes + i.prepMinutes + i.breakfastMinutes;
  if (needed >= firstClass.minutesSinceMidnight) {
    return ImpossibleMorning(firstClass: firstClass, neededMinutes: needed);
  }

  final leave = firstClass.plusMinutes(-i.commuteMinutes);
  final eatEnd = leave.plusMinutes(-i.prepMinutes);
  final eatStart = eatEnd.plusMinutes(-i.breakfastMinutes);
  final latestWake = eatStart;
  final tooLate = i.targetWake.compareTo(latestWake) > 0;
  final wake = tooLate ? latestWake : i.targetWake;

  return LeaveByPlan(
    firstClass: firstClass,
    wake: wake,
    eatStart: eatStart,
    eatEnd: eatEnd,
    leave: leave,
    wakeTooLate: tooLate,
    slackMinutes: eatStart.minutesSinceMidnight - wake.minutesSinceMidnight,
  );
}

enum LateAction {
  /// There is still time to get ready and leave at the planned time.
  getReady,

  /// Getting ready no longer fits: leaving now is the one thing to do.
  leaveNow,
}

/// The single next step for a morning that is running late.
class LatePlan {
  const LatePlan({
    required this.action,
    required this.leaveAt,
    required this.arriveAt,
    required this.minutesLate,
  });

  final LateAction action;
  final LocalTime leaveAt;
  final LocalTime arriveAt;

  /// Zero when [arriveAt] is at or before the class.
  final int minutesLate;

  bool get onTime => minutesLate == 0;
}

/// Pure: given the clock and the day's class, says what to do next and when
/// the owner would arrive. Never judges; it only answers "what now?".
LatePlan computeLatePlan({
  required LocalTime now,
  required LocalTime firstClass,
  required int commuteMinutes,
  required int prepMinutes,
}) {
  final leaveBy = firstClass.minutesSinceMidnight - commuteMinutes;
  final nowM = now.minutesSinceMidnight;
  if (nowM + prepMinutes <= leaveBy) {
    return LatePlan(
      action: LateAction.getReady,
      leaveAt: LocalTime(leaveBy),
      arriveAt: firstClass,
      minutesLate: 0,
    );
  }
  final arrive = nowM + commuteMinutes;
  return LatePlan(
    action: LateAction.leaveNow,
    leaveAt: now,
    arriveAt: LocalTime(arrive % LocalTime.minutesPerDay),
    minutesLate: (arrive - firstClass.minutesSinceMidnight).clamp(
      0,
      LocalTime.minutesPerDay,
    ),
  );
}
