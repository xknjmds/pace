import 'check_in_outcome.dart';
import '../time/local_time.dart';

/// Pure: the choice the check-in sheet preselects when the owner picks
/// [actual] for a step planned at [planned]. Past the plan by more than
/// [graceMinutes] reads as "a bit later"; the owner can always change it.
///
/// Times wrap around midnight, so a 22:30 wind-down logged at 00:40 is
/// later, not earlier.
CheckInOutcome suggestOutcome({
  required LocalTime? planned,
  required LocalTime actual,
  required int graceMinutes,
}) {
  if (planned == null) return CheckInOutcome.onTime;
  const day = LocalTime.minutesPerDay;
  var diff = actual.minutesSinceMidnight - planned.minutesSinceMidnight;
  if (diff >= day ~/ 2) diff -= day;
  if (diff < -day ~/ 2) diff += day;
  return diff > graceMinutes ? CheckInOutcome.later : CheckInOutcome.onTime;
}

/// Pure: the calm one-liner shown after a check-in is saved.
String checkInNote(CheckInOutcome outcome, LocalTime? at) => switch (outcome) {
  CheckInOutcome.onTime =>
    at == null ? 'Logged. Nicely done.' : 'Logged at ${at.format24()}.',
  CheckInOutcome.later =>
    at == null
        ? 'Logged. It still counts.'
        : 'Logged at ${at.format24()}. It still counts.',
  CheckInOutcome.didntHappen => 'Noted. Tomorrow\'s a fresh start.',
};

/// Pure: the instant the owner means when they pick [time] at [now]. A time
/// still ahead today means it already happened yesterday (a wind-down
/// logged after midnight, a deadline submitted last night).
DateTime resolvePickedTime(DateTime now, LocalTime time) {
  final today = time.onDate(now);
  return today.isAfter(now) ? today.subtract(const Duration(days: 1)) : today;
}
