import '../../../core/db/app_database.dart';
import '../../../core/time/local_time.dart';
import '../domain/morning_plan.dart';
import '../domain/wake_schedule.dart';

/// The wake plan stored in the settings row.
WakePlan wakePlanFrom(Setting s) {
  final goal = s.wakeGoalMinutes;
  final from = s.wakeShiftFromMinutes;
  final start = s.wakeShiftStartDate;
  return WakePlan(
    baseWakeMinutes: s.targetWakeMinutes,
    weekendLeewayMinutes: s.weekendLeewayMinutes,
    shift: goal == null || from == null || start == null
        ? null
        : WakeShift(
            fromMinutes: from,
            goalMinutes: goal,
            startDate: DateTime.parse(start),
            stepMinutes: s.wakeShiftStepMinutes,
            everyDays: s.wakeShiftEveryDays,
          ),
  );
}

/// Joins the settings row and one weekday's row into planner inputs.
/// A missing row means no class that day. With [date], the wake target is
/// the one in force that day (gradual shift, weekend leeway).
MorningInputs morningInputsFor(
  Setting settings,
  WeekdaySchedule? row, {
  DateTime? date,
}) => MorningInputs(
  firstClass: row?.firstClassMinutes == null
      ? null
      : LocalTime(row!.firstClassMinutes!),
  commuteMinutes: row?.commuteMinutes ?? 30,
  prepMinutes: row?.prepMinutes ?? 30,
  breakfastMinutes: settings.breakfastMinutes,
  targetWake: date == null
      ? LocalTime(settings.targetWakeMinutes)
      : wakeOn(wakePlanFrom(settings), date),
);
