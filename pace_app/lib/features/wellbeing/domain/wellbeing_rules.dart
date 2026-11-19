import '../../../core/time/date_key.dart';
import '../../routine/domain/wake_schedule.dart' show calendarDaysBetween;

/// Days away after which opening the app counts as coming back.
const returningAfterDays = 5;

/// Pure: whether this open is a return after a break. The very first open
/// (nothing recorded yet) is not a return.
bool isReturning({required DateTime? lastOpenedAt, required DateTime now}) {
  if (lastOpenedAt == null) return false;
  return calendarDaysBetween(lastOpenedAt.toLocal(), now) >= returningAfterDays;
}

/// Days looked back on when deciding mornings are steady.
const steadyLookbackDays = 21;

/// Routine-done days within [steadyLookbackDays] that count as steady:
/// about four mornings a week for three weeks.
const steadyDaysNeeded = 12;

/// A "no thanks" is respected this long before asking again.
const steadyAskAgainDays = 60;

/// Pure: whether to gently offer steady mode (fewer reminders).
///
/// [routineDoneDates] are local dates on which the morning routine was
/// done. Only the last [steadyLookbackDays] count.
bool shouldOfferSteady({
  required Iterable<DateTime> routineDoneDates,
  required DateTime now,
  required bool steadyMode,
  required DateTime? dismissedAt,
}) {
  if (steadyMode) return false;
  if (dismissedAt != null &&
      calendarDaysBetween(dismissedAt.toLocal(), now) < steadyAskAgainDays) {
    return false;
  }
  final recent = routineDoneDates
      .where((d) {
        final ago = calendarDaysBetween(d, now);
        return ago >= 0 && ago < steadyLookbackDays;
      })
      .map(dateKey)
      .toSet();
  return recent.length >= steadyDaysNeeded;
}

/// Pure: a neutral line about the evenings' answers, or null with none.
/// Counts only, in a fixed order, so no answer stands out as "bad".
String? moodSummary({
  required int good,
  required int okay,
  required int drained,
}) {
  final parts = [
    if (good > 0) '$good good',
    if (okay > 0) '$okay okay',
    if (drained > 0) '$drained drained',
  ];
  if (parts.isEmpty) return null;
  return 'Evenings: ${parts.join(' · ')}';
}
