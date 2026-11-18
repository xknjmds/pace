import '../../../core/time/date_key.dart';
import '../../../core/time/local_time.dart';

/// Everything that decides the wake time on a given date. Plain values,
/// built from the settings row by the application layer.
class WakePlan {
  const WakePlan({
    required this.baseWakeMinutes,
    this.weekendLeewayMinutes = 60,
    this.shift,
  });

  /// The weekday wake time when no shift is under way.
  final int baseWakeMinutes;

  /// Saturday and Sunday may be this much later, at most an hour.
  final int weekendLeewayMinutes;
  final WakeShift? shift;
}

/// Moving the wake time earlier a little at a time.
class WakeShift {
  const WakeShift({
    required this.fromMinutes,
    required this.goalMinutes,
    required this.startDate,
    this.stepMinutes = 15,
    this.everyDays = 3,
  }) : assert(stepMinutes > 0 && everyDays > 0);

  final int fromMinutes;
  final int goalMinutes;

  /// Local date the shift began; only its calendar day matters.
  final DateTime startDate;
  final int stepMinutes;
  final int everyDays;
}

/// The longest weekend leeway the app allows.
const maxWeekendLeewayMinutes = 60;

/// Whole calendar days from [from] to [to], immune to DST hour changes.
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = dateOnly(from);
  final b = dateOnly(to);
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Pure: the shifted weekday wake time on [date], in minutes.
///
/// Based only on the calendar, never on what was logged, so a missed or
/// late night never resets the schedule. Never goes past the goal.
int gradualWakeMinutes(WakeShift shift, DateTime date) {
  final days = calendarDaysBetween(shift.startDate, date);
  if (days <= 0) return shift.fromMinutes;
  final steps = days ~/ shift.everyDays;
  if (shift.goalMinutes >= shift.fromMinutes) return shift.goalMinutes;
  final moved = shift.fromMinutes - steps * shift.stepMinutes;
  return moved < shift.goalMinutes ? shift.goalMinutes : moved;
}

/// Pure: first date on which the shift sits at its goal.
DateTime shiftReachesGoalOn(WakeShift shift) {
  final gap = shift.fromMinutes - shift.goalMinutes;
  final start = dateOnly(shift.startDate);
  if (gap <= 0) return start;
  final steps = (gap + shift.stepMinutes - 1) ~/ shift.stepMinutes;
  return DateTime(start.year, start.month, start.day + steps * shift.everyDays);
}

bool isWeekend(DateTime date) =>
    date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

/// Pure: the weekday wake time in force on [date].
LocalTime weekdayWakeOn(WakePlan plan, DateTime date) {
  final shift = plan.shift;
  return LocalTime(
    shift == null ? plan.baseWakeMinutes : gradualWakeMinutes(shift, date),
  );
}

/// Pure: the wake time for [date]. Weekends get the leeway, capped at an
/// hour, so the body clock stays roughly where the week left it.
LocalTime wakeOn(WakePlan plan, DateTime date) {
  final weekday = weekdayWakeOn(plan, date);
  if (!isWeekend(date)) return weekday;
  final leeway = plan.weekendLeewayMinutes.clamp(0, maxWeekendLeewayMinutes);
  final m = weekday.minutesSinceMidnight + leeway;
  return LocalTime(
    m >= LocalTime.minutesPerDay ? LocalTime.minutesPerDay - 1 : m,
  );
}

/// The evening a bedtime belongs to: before noon counts as last night.
DateTime nightOf(DateTime at) {
  final d = dateOnly(at);
  return at.hour < 12 ? DateTime(d.year, d.month, d.day - 1) : d;
}

/// The night that starts on [night] (local date): when to wind down, when
/// to be in bed, and when the next morning's wake is.
class NightPlan {
  const NightPlan({
    required this.night,
    required this.windDownAt,
    required this.bedtime,
    required this.wakeAt,
  });

  final DateTime night;
  final DateTime windDownAt;
  final DateTime bedtime;
  final DateTime wakeAt;
}

/// Pure: bedtime is the next morning's wake time minus the sleep target.
NightPlan nightPlan({
  required WakePlan plan,
  required DateTime night,
  required int sleepTargetMinutes,
  required int windDownLeadMinutes,
}) {
  final n = dateOnly(night);
  final morning = DateTime(n.year, n.month, n.day + 1);
  final wakeAt = wakeOn(plan, morning).onDate(morning);
  final bedtime = wakeAt.subtract(Duration(minutes: sleepTargetMinutes));
  return NightPlan(
    night: n,
    windDownAt: bedtime.subtract(Duration(minutes: windDownLeadMinutes)),
    bedtime: bedtime,
    wakeAt: wakeAt,
  );
}
