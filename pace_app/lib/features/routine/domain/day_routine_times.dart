import 'morning_plan.dart';
import 'wake_schedule.dart';

/// The routine's fixed points on one local day, as instants. [eat] and
/// [leave] are null on days without a class (or when the morning cannot
/// fit). The night belongs to [date]: wind-down and bed that evening,
/// waking the next morning.
class DayRoutineTimes {
  const DayRoutineTimes({
    required this.date,
    required this.wake,
    required this.windDown,
    required this.bedtime,
    required this.nextWake,
    this.eat,
    this.leave,
  });

  final DateTime date;
  final DateTime wake;
  final DateTime? eat;
  final DateTime? leave;
  final DateTime windDown;
  final DateTime bedtime;
  final DateTime nextWake;
}

/// Pure: where the routine puts wake, breakfast, leaving and wind-down on
/// [date]. [inputs] must already carry that date's wake target.
DayRoutineTimes routineTimesOn({
  required DateTime date,
  required MorningInputs inputs,
  required WakePlan plan,
  required int sleepTargetMinutes,
  required int windDownLeadMinutes,
}) {
  final morning = computeLeaveByPlan(inputs);
  final night = nightPlan(
    plan: plan,
    night: date,
    sleepTargetMinutes: sleepTargetMinutes,
    windDownLeadMinutes: windDownLeadMinutes,
  );
  final leaveBy = morning is LeaveByPlan ? morning : null;
  return DayRoutineTimes(
    date: DateTime(date.year, date.month, date.day),
    wake: (leaveBy?.wake ?? inputs.targetWake).onDate(date),
    eat: leaveBy?.eatStart.onDate(date),
    leave: leaveBy?.leave.onDate(date),
    windDown: night.windDownAt,
    bedtime: night.bedtime,
    nextWake: night.wakeAt,
  );
}
