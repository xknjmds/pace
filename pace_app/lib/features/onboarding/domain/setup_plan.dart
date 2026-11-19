import '../../../core/time/local_time.dart';
import '../../routine/domain/morning_plan.dart';

/// How the owner's body clock leans. Only shapes how gently the wake time
/// moves and how long the weekend lie-in is.
enum Chronotype { morning, inBetween, night }

/// What the first-run setup asks. Plain values, no database types.
class SetupAnswers {
  const SetupAnswers({
    required this.classDays,
    required this.firstClass,
    required this.commuteMinutes,
    required this.prepMinutes,
    required this.usualWake,
    required this.sleepTargetMinutes,
    required this.chronotype,
    this.breakfastMinutes = 15,
  });

  /// [DateTime.monday] to [DateTime.sunday].
  final Set<int> classDays;
  final LocalTime firstClass;
  final int commuteMinutes;
  final int prepMinutes;
  final LocalTime usualWake;
  final int sleepTargetMinutes;
  final Chronotype chronotype;
  final int breakfastMinutes;
}

class SetupDay {
  const SetupDay({
    required this.firstClassMinutes,
    required this.commuteMinutes,
    required this.prepMinutes,
  });

  final int? firstClassMinutes;
  final int commuteMinutes;
  final int prepMinutes;
}

/// How the wake time is set.
sealed class WakeChoice {
  const WakeChoice();
}

/// Use this wake time from today.
class WakeNow extends WakeChoice {
  const WakeNow(this.minutes);
  final int minutes;
}

/// Start at the usual wake time and move toward [goalMinutes] a little at
/// a time (the existing gradual wake shift).
class WakeGradually extends WakeChoice {
  const WakeGradually({
    required this.fromMinutes,
    required this.goalMinutes,
    required this.stepMinutes,
    required this.everyDays,
  });

  final int fromMinutes;
  final int goalMinutes;
  final int stepMinutes;
  final int everyDays;
}

class SetupPlan {
  const SetupPlan({
    required this.days,
    required this.wake,
    required this.sleepTargetMinutes,
    required this.weekendLeewayMinutes,
    required this.breakfastMinutes,
    required this.leaveBy,
  });

  /// One entry per weekday, [DateTime.monday] to [DateTime.sunday].
  final Map<int, SetupDay> days;
  final WakeChoice wake;
  final int sleepTargetMinutes;
  final int weekendLeewayMinutes;
  final int breakfastMinutes;

  /// When to leave on a class day, for the summary. Null without classes
  /// or when the morning cannot fit.
  final LocalTime? leaveBy;
}

/// Room left between the goal wake time and the latest workable one.
const _roomMinutes = 15;

/// A gap this small is closed at once rather than step by step.
const _directGapMinutes = 30;

/// Pure: turns the setup answers into settings for the routine.
///
/// Keeps the usual wake time when the morning allows it. When it does not,
/// the goal is the latest workable wake on the earliest class day, minus a
/// little room. A small gap is closed at once; a bigger one uses the
/// gradual wake shift so the change never feels like a shock.
SetupPlan planFromAnswers(SetupAnswers a) {
  final days = {
    for (var d = DateTime.monday; d <= DateTime.sunday; d++)
      d: SetupDay(
        firstClassMinutes: a.classDays.contains(d)
            ? a.firstClass.minutesSinceMidnight
            : null,
        commuteMinutes: a.commuteMinutes,
        prepMinutes: a.prepMinutes,
      ),
  };

  final leeway = switch (a.chronotype) {
    Chronotype.morning => 30,
    Chronotype.inBetween => 45,
    Chronotype.night => 60,
  };

  final usual = a.usualWake.minutesSinceMidnight;
  WakeChoice wake = WakeNow(usual);
  LocalTime? leaveBy;

  if (a.classDays.isNotEmpty) {
    final morning = computeLeaveByPlan(
      MorningInputs(
        firstClass: a.firstClass,
        commuteMinutes: a.commuteMinutes,
        prepMinutes: a.prepMinutes,
        breakfastMinutes: a.breakfastMinutes,
        targetWake: a.usualWake,
      ),
    );
    if (morning is LeaveByPlan) {
      leaveBy = morning.leave;
      if (morning.wakeTooLate) {
        final latest = morning.eatStart.minutesSinceMidnight;
        final goal = _roundDownTo5(
          (latest - _roomMinutes).clamp(0, latest).toInt(),
        );
        if (usual - goal <= _directGapMinutes) {
          wake = WakeNow(goal);
        } else {
          final night = a.chronotype == Chronotype.night;
          wake = WakeGradually(
            fromMinutes: usual,
            goalMinutes: goal,
            stepMinutes: night ? 10 : 15,
            everyDays: night ? 4 : 3,
          );
        }
      }
    }
  }

  return SetupPlan(
    days: days,
    wake: wake,
    sleepTargetMinutes: a.sleepTargetMinutes,
    weekendLeewayMinutes: leeway,
    breakfastMinutes: a.breakfastMinutes,
    leaveBy: leaveBy,
  );
}

int _roundDownTo5(int minutes) => minutes - minutes % 5;
